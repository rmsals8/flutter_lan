// lib/services/alarm_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:just_audio/just_audio.dart';
import './alarm_receiver.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';

import '../models/alarm.dart';

class AlarmService {
  static final AlarmService _instance = AlarmService._internal();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  // 싱글톤 패턴
  factory AlarmService() => _instance;
  
  AlarmService._internal();

  Future<void> initialize() async {
    if (_isInitialized) return;

    // 타임존 초기화
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Seoul'));

    // Android Alarm Manager 초기화
    await AndroidAlarmManager.initialize();

    // 안드로이드 설정
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS 설정
    final DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings();

    // 초기화 설정
    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    // 플러그인 초기화
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
    );
    
    // 부팅 시 알람 복원 체크
    _checkAndRestoreAlarms();

    _isInitialized = true;
    debugPrint('AlarmService 초기화 완료');
  }
  
  // 부팅 후 알람 복원
  Future<void> _checkAndRestoreAlarms() async {
    try {
      final alarms = await loadAlarms();
      for (final alarm in alarms) {
        if (alarm.isEnabled) {
          await scheduleAlarm(alarm);
        }
      }
      debugPrint('알람 복원 완료: ${alarms.where((a) => a.isEnabled).length}개');
    } catch (e) {
      debugPrint('알람 복원 오류: $e');
    }
  }

  // 알림 응답 처리 콜백
  void onDidReceiveNotificationResponse(NotificationResponse response) {
    debugPrint('알림 응답: ${response.payload}');
    
    // 알람음 재생
    if (response.payload != null && response.payload!.isNotEmpty) {
      playAlarmSound(response.payload!);
    } else {
      // 기본 알람음 재생
      playAlarmSound('assets/default_alarm.mp3');
    }
  }

  // 알람 저장
  Future<void> saveAlarms(List<Alarm> alarms) async {
    final prefs = await SharedPreferences.getInstance();
    final alarmsJson = alarms.map((alarm) => jsonEncode(alarm.toJson())).toList();
    await prefs.setStringList('alarms', alarmsJson);
    debugPrint('알람 저장 완료: ${alarms.length}개');
  }
  
  // 알람 불러오기
  Future<List<Alarm>> loadAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final alarmsJson = prefs.getStringList('alarms') ?? [];
    
    final List<Alarm> alarms = [];
    for (final json in alarmsJson) {
      try {
        final alarm = Alarm.fromJson(jsonDecode(json));
        alarms.add(alarm);
      } catch (e) {
        debugPrint('알람 데이터 파싱 오류: $e');
      }
    }
    
    debugPrint('알람 불러오기 완료: ${alarms.length}개');
    return alarms;
  }

  // 알람 추가
  Future<void> addAlarm(Alarm alarm) async {
    final alarms = await loadAlarms();
    
    // ID 중복 방지
    int maxId = 0;
    for (final a in alarms) {
      if (a.id > maxId) maxId = a.id;
    }
    
    // ID가 0이면 새 ID 할당
    final newAlarm = alarm.id == 0 
        ? alarm.copyWith(id: maxId + 1) 
        : alarm;
    
    alarms.add(newAlarm);
    await saveAlarms(alarms);
    
    if (newAlarm.isEnabled) {
      await scheduleAlarm(newAlarm);
    }
    
    debugPrint('알람 추가 완료: ID=${newAlarm.id}, 시간=${newAlarm.time.hour}:${newAlarm.time.minute}');
  }
  
  // 알람 업데이트
  Future<void> updateAlarm(Alarm alarm) async {
    final alarms = await loadAlarms();
    final index = alarms.indexWhere((a) => a.id == alarm.id);
    
    if (index != -1) {
      // 기존 알람 취소 (안전한 ID 사용)
      await cancelAlarm(alarms[index]);
      
      // 알람 업데이트
      alarms[index] = alarm;
      await saveAlarms(alarms);
      
      // 활성화된 경우 다시 예약 (안전한 ID 사용)
      if (alarm.isEnabled) {
        await scheduleAlarm(alarm);
      }
      
      debugPrint('알람 업데이트 완료: ID=${alarm.id}, 활성화=${alarm.isEnabled}, 시간=${alarm.time.hour}:${alarm.time.minute}');
    } else {
      debugPrint('업데이트할 알람을 찾을 수 없음: ID=${alarm.id}');
    }
  }
  
  // 알람 삭제
  Future<void> deleteAlarm(int alarmId) async {
    final alarms = await loadAlarms();
    final alarmIndex = alarms.indexWhere((a) => a.id == alarmId);
    
    if (alarmIndex != -1) {
      final alarm = alarms[alarmIndex];
      // 안전한 ID로 알람 취소
      await cancelAlarm(alarm);
      
      // 알람 목록에서 제거
      alarms.removeAt(alarmIndex);
      await saveAlarms(alarms);
      
      debugPrint('알람 삭제 완료: ID=$alarmId');
    } else {
      debugPrint('삭제할 알람을 찾을 수 없음: ID=$alarmId');
    }
  }

  // 간단한 알림 표시
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await initialize();

    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'alarm_channel',
      '알람',
      channelDescription: '알람 알림 채널',
      importance: Importance.max,
      priority: Priority.high,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
    );

    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidNotificationDetails);

    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
    
    debugPrint('알림 표시: ID=$id, 제목=$title');
  }

  // 알람 콜백 함수 - AndroidAlarmManager에서 호출됨
  // vm:entry-point 추가
  @pragma('vm:entry-point')
  static Future<void> _alarmCallback(int id) async {
    debugPrint('알람 콜백 실행: ID=$id');
    
    // 인스턴스 가져오기
    final alarmService = AlarmService();
    
    // SharedPreferences에서 알람 정보 가져오기
    final prefs = await SharedPreferences.getInstance();
    final alarmJson = prefs.getString('alarm_data_$id');
    
    if (alarmJson != null) {
      try {
        final alarmMap = jsonDecode(alarmJson) as Map<String, dynamic>;
        final label = alarmMap['label'] as String? ?? '알람';
        final soundPath = alarmMap['soundPath'] as String? ?? 'assets/default_alarm.mp3';
        
        // 알림 표시
        await alarmService.showNotification(
          id: id,
          title: label,
          body: '알람 시간입니다',
          payload: soundPath,
        );
        
        // 알람 소리 재생
        await alarmService.playAlarmSound(soundPath);
        
        // 반복 알람인 경우 다음 알람 예약
        final isRepeating = alarmMap['isRepeating'] as bool? ?? false;
        if (isRepeating) {
          final repeatDaysJson = alarmMap['repeatDays'] as List<dynamic>?;
          final hour = alarmMap['hour'] as int? ?? 0;
          final minute = alarmMap['minute'] as int? ?? 0;
          
          if (repeatDaysJson != null) {
            final repeatDays = List<bool>.from(repeatDaysJson.map((e) => e as bool));
            final alarm = Alarm(
              id: alarmMap['id'] as int? ?? id,
              time: TimeOfDay(hour: hour, minute: minute),
              repeatDays: repeatDays,
              label: label,
              soundPath: soundPath,
              soundName: alarmMap['soundName'] as String? ?? '알람음',
            );
            
            // 다음 알람 예약
            await alarmService.scheduleAlarm(alarm);
          }
        }
      } catch (e) {
        debugPrint('알람 데이터 파싱 오류: $e');
      }
    } else {
      // 알람 데이터가 없는 경우 기본 알림 표시
      await alarmService.showNotification(
        id: id,
        title: '알람',
        body: '알람 시간입니다',
      );
    }
  }

  // 알람 예약
    Future<void> scheduleAlarm(Alarm alarm) async {
    await initialize();

    final alarmTime = _calculateNextAlarmTime(alarm);
    if (alarmTime == null) {
      debugPrint('알람 예약 실패: 다음 알람 시간을 계산할 수 없음');
      return;
    }

    // 고유한 알람 ID 생성 (알람 ID + 시간 정보)
    int uniqueId = alarm.id * 10000 + (alarm.time.hour * 100 + alarm.time.minute);
    
    // 32비트 정수 범위 내로 제한
    int safeId = uniqueId % 2000000000;

    // 알람 데이터 저장 (콜백에서 사용)
    final prefs = await SharedPreferences.getInstance();
    final alarmData = {
      'id': alarm.id,
      'hour': alarm.time.hour,
      'minute': alarm.time.minute,
      'label': alarm.label,
      'soundPath': alarm.soundPath,
      'soundName': alarm.soundName,
      'isRepeating': alarm.repeatDays.contains(true),
      'repeatDays': alarm.repeatDays,
    };
    await prefs.setString('alarm_data_$safeId', jsonEncode(alarmData));
    
    // 알람 매니저로 예약
    final now = DateTime.now();
    final alarmDateTime = DateTime(
      alarmTime.year,
      alarmTime.month,
      alarmTime.day,
      alarmTime.hour,
      alarmTime.minute,
      0,  // 초를 0으로 설정
    );
    
    // 이미 지난 시간이면 내일로 설정
    if (alarmDateTime.isBefore(now)) {
      debugPrint('이미 지난 시간입니다. 내일로 설정합니다.');
      final newAlarmDateTime = alarmDateTime.add(const Duration(days: 1));
      debugPrint('새 알람 시간: ${newAlarmDateTime.toString()}');
      
      // 안드로이드 알람 매니저 예약
      final success = await AndroidAlarmManager.oneShotAt(
        newAlarmDateTime,
        safeId,
        AlarmReceiver.onAlarm,  // AlarmService._alarmCallback 대신 AlarmReceiver.onAlarm 사용
        exact: true,
        wakeup: true,
        rescheduleOnReboot: true,
        alarmClock: true,
      );
      
      if (success) {
        debugPrint('AndroidAlarmManager 알람 예약 성공 (다음날): ID=$safeId, 시간=${newAlarmDateTime.toString()}');
        
        // Flutter Local Notifications로도 예약 (백업)
        try {
          // 안드로이드 알림 설정
          final AndroidNotificationDetails androidNotificationDetails =
              AndroidNotificationDetails(
            'alarm_channel',
            '알람',
            channelDescription: '알람 알림 채널',
            importance: Importance.max,
            priority: Priority.high,
            fullScreenIntent: true,
            category: AndroidNotificationCategory.alarm,
          );

          final NotificationDetails notificationDetails =
              NotificationDetails(android: androidNotificationDetails);

          // Flutter Local Notifications로 예약
          await flutterLocalNotificationsPlugin.zonedSchedule(
            safeId,
            alarm.label,
            '알람 시간입니다',
            tz.TZDateTime.from(newAlarmDateTime, tz.local),
            notificationDetails,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            payload: alarm.soundPath,
          );
          
          debugPrint('FlutterLocalNotifications 알람 예약 성공 (다음날): ID=$safeId');
        } catch (e) {
          debugPrint('FlutterLocalNotifications 알람 예약 실패: $e');
        }
      } else {
        debugPrint('알람 예약 실패: ID=$safeId');
      }
      
      return;
    }
    
    // 안드로이드 알람 매니저 예약 (정상적인 미래 시간)
    final success = await AndroidAlarmManager.oneShotAt(
      alarmDateTime,
      safeId,
      AlarmReceiver.onAlarm,  // AlarmService._alarmCallback 대신 AlarmReceiver.onAlarm 사용
      exact: true,
      wakeup: true,
      rescheduleOnReboot: true,
      alarmClock: true,
    );
    
    if (success) {
      debugPrint('AndroidAlarmManager 알람 예약 성공: ID=$safeId, 시간=${alarmDateTime.toString()}');
      
      // Flutter Local Notifications로도 예약 (백업)
      try {
        // 안드로이드 알림 설정
        final AndroidNotificationDetails androidNotificationDetails =
            AndroidNotificationDetails(
          'alarm_channel',
          '알람',
          channelDescription: '알람 알림 채널',
          importance: Importance.max,
          priority: Priority.high,
          fullScreenIntent: true,
          category: AndroidNotificationCategory.alarm,
        );

        final NotificationDetails notificationDetails =
            NotificationDetails(android: androidNotificationDetails);

        // Flutter Local Notifications로 예약
        await flutterLocalNotificationsPlugin.zonedSchedule(
          safeId,
          alarm.label,
          '알람 시간입니다',
          tz.TZDateTime.from(alarmDateTime, tz.local),
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: alarm.soundPath,
        );
        
        debugPrint('FlutterLocalNotifications 알람 예약 성공: ID=$safeId');
      } catch (e) {
        debugPrint('FlutterLocalNotifications 알람 예약 실패: $e');
      }
    } else {
      debugPrint('알람 예약 실패: ID=$safeId');
    }
  }
  
  // 알람 취소
  Future<void> cancelAlarm(Alarm alarm) async {
    // 고유한 알람 ID 생성 (알람 ID + 시간 정보)
    int uniqueId = alarm.id * 10000 + (alarm.time.hour * 100 + alarm.time.minute);
    
    // 32비트 정수 범위 내로 제한
    int safeId = uniqueId % 2000000000;
    
    // AndroidAlarmManager 알람 취소
    final success = await AndroidAlarmManager.cancel(safeId);
    debugPrint('AndroidAlarmManager 알람 취소: ID=$safeId, 성공=${success ? '성공' : '실패'}');
    
    // FlutterLocalNotifications 알람 취소
    await flutterLocalNotificationsPlugin.cancel(safeId);
    debugPrint('FlutterLocalNotifications 알람 취소: ID=$safeId');
    
    // 저장된 알람 데이터 삭제
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('alarm_data_$safeId');
  }
  
  // 모든 알람 취소
  Future<void> cancelAllAlarms() async {
    // 저장된 모든 알람 불러오기
    final alarms = await loadAlarms();
    
    // 각 알람 취소
    for (final alarm in alarms) {
      await cancelAlarm(alarm);
    }
    
    // FlutterLocalNotifications의 모든 알람 취소
    await flutterLocalNotificationsPlugin.cancelAll();
    
    debugPrint('모든 알람 취소 완료');
  }

  // 알람음 재생
  Future<void> playAlarmSound(String soundPath) async {
    try {
      debugPrint('알람음 재생 시도: $soundPath');
      
      await _audioPlayer.stop();
      
      // 경로 유형에 따라 다르게 처리
      if (soundPath.startsWith('assets/')) {
        // 앱 에셋 파일
        await _audioPlayer.setAsset(soundPath);
        debugPrint('에셋 파일 로드: $soundPath');
      } else if (soundPath.startsWith('file://')) {
        // 로컬 파일 (file:// 프로토콜 사용)
        final path = soundPath.replaceFirst('file://', '');
        await _audioPlayer.setFilePath(path);
        debugPrint('파일 경로 로드 (file://): $path');
      } else if (soundPath.isNotEmpty && File(soundPath).existsSync()) {
        // 일반 로컬 파일 경로
        await _audioPlayer.setFilePath(soundPath);
        debugPrint('파일 경로 로드: $soundPath');
      } else {
        // 기본 알람음으로 폴백
        await _audioPlayer.setAsset('assets/default_alarm.mp3');
        debugPrint('기본 알람음으로 폴백');
      }
      
      // 루프 재생 설정
      await _audioPlayer.setLoopMode(LoopMode.one);
      // 볼륨 최대로 설정
      await _audioPlayer.setVolume(1.0);
      
      // 재생 시작
      await _audioPlayer.play();
      debugPrint('알람음 재생 시작');
    } catch (e) {
      debugPrint('알람음 재생 오류: $e');
      
      // 오류 발생 시 기본 알람음으로 폴백
      try {
        await _audioPlayer.setAsset('assets/default_alarm.mp3');
        await _audioPlayer.setLoopMode(LoopMode.one);
        await _audioPlayer.setVolume(1.0);
        await _audioPlayer.play();
        debugPrint('기본 알람음으로 폴백 재생');
      } catch (fallbackError) {
        debugPrint('기본 알람음 재생 오류: $fallbackError');
      }
    }
  }
  
  // 알람음 정지
  Future<void> stopAlarmSound() async {
    try {
      await _audioPlayer.stop();
      debugPrint('알람음 정지');
    } catch (e) {
      debugPrint('알람음 정지 오류: $e');
    }
  }

  // 다음 알람 시간 계산
  DateTime? _calculateNextAlarmTime(Alarm alarm) {
    final now = DateTime.now();
    
    // 현재 요일 (1: 월요일, 7: 일요일)
    final currentDay = now.weekday;
    
    // 현재 시간 (분 단위)
    final currentTimeInMinutes = now.hour * 60 + now.minute;
    
    // 알람 시간 (분 단위)
    final alarmTimeInMinutes = alarm.time.hour * 60 + alarm.time.minute;
    
    // 반복 없는 경우
    if (!alarm.repeatDays.contains(true)) {
      final alarmTime = DateTime(
        now.year,
        now.month,
        now.day,
        alarm.time.hour,
        alarm.time.minute,
        0,  // 초를 0으로 설정
      );
      
      // 오늘 알람 시간이 현재 시간보다 이후면 오늘 알람
      if (alarmTimeInMinutes > currentTimeInMinutes) {
        debugPrint('반복 없음, 오늘 알람: ${alarmTime.toString()}');
        return alarmTime;
      }
      // 아니면 내일 알람
      final tomorrowAlarm = alarmTime.add(const Duration(days: 1));
      debugPrint('반복 없음, 내일 알람: ${tomorrowAlarm.toString()}');
      return tomorrowAlarm;
    }
    
    // 요일 반복이 있는 경우
    // Flutter의 weekday는 1(월요일)~7(일요일)이지만
    // 우리 앱의 repeatDays는 0(월요일)~6(일요일)로 되어있음
    for (int daysToAdd = 0; daysToAdd < 7; daysToAdd++) {
      // 확인할 요일 계산 (주의: repeatDays는 0부터 시작, weekday는 1부터 시작)
      final dayToCheck = (currentDay + daysToAdd - 1) % 7;
      
      // 해당 요일에 알람이 설정되어 있다면
      if (alarm.repeatDays[dayToCheck]) {
        // 오늘이고 현재 시간이 알람 시간보다 이전이면 오늘 알람
        if (daysToAdd == 0 && alarmTimeInMinutes > currentTimeInMinutes) {
          final todayAlarm = DateTime(
            now.year,
            now.month,
            now.day,
            alarm.time.hour,
            alarm.time.minute,
            0,  // 초를 0으로 설정
          );
          debugPrint('요일 반복, 오늘(${_getDayName(currentDay)}) 알람: ${todayAlarm.toString()}');
          return todayAlarm;
        } 
        // 오늘이 아니거나, 오늘이지만 알람 시간이 지났으면 해당 요일로 날짜 계산
        else if (daysToAdd > 0) {
          final futureAlarm = DateTime(
            now.year,
            now.month,
            now.day + daysToAdd,
            alarm.time.hour,
            alarm.time.minute,
            0,  // 초를 0으로 설정
          );
          final futureDayOfWeek = (currentDay + daysToAdd) % 7;
          // 0 대신 7(일요일)로 표시 - 수정된 부분
          final adjustedDay = futureDayOfWeek == 0 ? 7 : futureDayOfWeek;
          debugPrint('요일 반복, ${daysToAdd}일 후(${_getDayName(adjustedDay)}) 알람: ${futureAlarm.toString()}');
          return futureAlarm;
        }
      }
    }
    
    // 모든 반복 요일이 비활성화된 경우 (일어나지 않아야 함)
    debugPrint('적절한 알람 시간을 찾을 수 없음');
    return null;
  }
  
  // 요일 이름 반환 (디버깅용)
  String _getDayName(int weekday) {
    const days = ['월', '화', '수', '목', '금', '토', '일'];
    return days[(weekday - 1) % 7];
  }
}