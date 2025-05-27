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
import '../main.dart' show alarmCallback, navigatorKey; // main.dart에서 필요한 것들만 import
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

    // 알림 채널 설정 (중요: Android 8.0 이상에서 필요)
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'alarm_channel',
      '알람',
      description: '알람 알림 채널',
      importance: Importance.max,
      playSound: true,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

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

  // 알림 응답 처리 콜백 - 알람 화면 표시 기능 추가
  void onDidReceiveNotificationResponse(NotificationResponse response) {
    debugPrint('알림 응답: ${response.payload}');

    // 알림을 탭했을 때 알람 화면 표시
    if (response.payload != null && response.payload!.startsWith('alarm_')) {
      final alarmIdStr = response.payload!.replaceFirst('alarm_', '');

      try {
        final alarmId = int.parse(alarmIdStr);
        _showAlarmScreen(alarmId);
      } catch (e) {
        debugPrint('알람 ID 파싱 오류: $e');
      }
    }

    // 알람음 재생
    if (response.payload != null && response.payload!.isNotEmpty) {
      playAlarmSound('assets/default_alarm.mp3');
    } else {
      // 기본 알람음 재생
      playAlarmSound('assets/default_alarm.mp3');
    }
  }

  // 알람 화면을 표시하는 기능
  Future<void> _showAlarmScreen(int alarmId) async {
    try {
      debugPrint('AlarmService: 알람 화면 표시 시도 - ID: $alarmId');

      // 저장된 알람 데이터에서 해당 알람 찾기
      final alarms = await loadAlarms();
      final alarm = alarms.firstWhere(
            (a) => a.id == alarmId,
        orElse: () => Alarm(
          id: alarmId,
          time: TimeOfDay.now(),
          repeatDays: List.filled(7, false),
          label: '알람',
          soundPath: 'assets/default_alarm.mp3',
          soundName: '기본 알람음',
        ),
      );

      // 앱이 실행 중이고 네비게이터가 준비되어 있다면 화면 표시
      if (navigatorKey.currentContext != null) {
        debugPrint('AlarmService: 알람 화면으로 이동');

        // 알람 화면으로 이동
        navigatorKey.currentState?.pushNamed(
          '/alarm-ringing',
          arguments: {'alarm': alarm},
        );
      } else {
        debugPrint('AlarmService: 앱이 실행되지 않음, 알림만 표시');
      }
    } catch (e) {
      debugPrint('AlarmService: 알람 화면 표시 오류: $e');
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
    debugPrint('======== 알람 업데이트 시작: ID=${alarm.id}, 시간=${alarm.time.hour}:${alarm.time.minute} ========');

    final alarms = await loadAlarms();
    final index = alarms.indexWhere((a) => a.id == alarm.id);

    if (index != -1) {
      final oldAlarm = alarms[index];

      // 1. 기존 알람의 모든 가능한 ID로 취소 시도
      debugPrint('알람 업데이트: 기존 알람 취소 시작');
      await _cancelAllVariationsOfAlarm(oldAlarm);

      // 2. 잠시 기다림 (시스템이 취소를 처리할 시간을 줌)
      await Future.delayed(const Duration(milliseconds: 500));

      // 3. 알람 목록 업데이트
      alarms[index] = alarm;
      await saveAlarms(alarms);
      debugPrint('알람 업데이트: 알람 목록 저장 완료');

      // 4. 새 알람이 활성화된 경우에만 다시 예약
      if (alarm.isEnabled) {
        debugPrint('알람 업데이트: 새 알람 예약 시작');
        await scheduleAlarm(alarm);
        debugPrint('알람 업데이트: 새 알람 예약 완료');
      } else {
        debugPrint('알람 업데이트: 알람이 비활성화 상태이므로 예약하지 않음');
      }

      debugPrint('알람 업데이트 완료: ID=${alarm.id}, 활성화=${alarm.isEnabled}, 시간=${alarm.time.hour}:${alarm.time.minute}');
    } else {
      debugPrint('업데이트할 알람을 찾을 수 없음: ID=${alarm.id}');
      // 알람이 없다면 새로 추가
      debugPrint('알람을 새로 추가합니다');
      await addAlarm(alarm);
    }
  }

// 알람의 모든 가능한 ID 변형을 취소하는 새로운 메서드
  Future<void> _cancelAllVariationsOfAlarm(Alarm alarm) async {
    debugPrint('알람: 모든 변형 ID 취소 시작');

    // 기본 ID 계산
    int baseId = alarm.id * 10000 + (alarm.time.hour * 100 + alarm.time.minute);
    int safeId = baseId % 1000000;

    // 여러 가능한 ID로 취소 시도
    List<int> possibleIds = [
      safeId,
      alarm.id,
      baseId,
      alarm.id * 1000 + alarm.time.hour * 10 + (alarm.time.minute ~/ 10),
    ];

    for (int id in possibleIds) {
      try {
        // AndroidAlarmManager 취소
        await AndroidAlarmManager.cancel(id);
        debugPrint('알람: AndroidAlarmManager 취소 시도 - ID: $id');

        // FlutterLocalNotifications 취소
        await flutterLocalNotificationsPlugin.cancel(id);
        debugPrint('알람: FlutterLocalNotifications 취소 시도 - ID: $id');

        // SharedPreferences 데이터 삭제
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('alarm_data_$id');
        debugPrint('알람: SharedPreferences 데이터 삭제 - ID: $id');

      } catch (e) {
        debugPrint('알람: ID $id 취소 중 오류 (무시): $e');
      }
    }

    debugPrint('알람: 모든 변형 ID 취소 완료');
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

  // 알람 예약 메서드 - 화면 표시 기능 추가
// 알람 예약 메서드 - 간소화된 버전
  Future<void> scheduleAlarm(Alarm alarm) async {
    debugPrint('======== 알람 예약 시작: ID=${alarm.id}, 시간=${alarm.time.hour}:${alarm.time.minute} ========');

    await initialize();
    debugPrint('알람 예약: 서비스 초기화 완료');

    // 다음 알람 시간 계산
    final alarmTime = _calculateNextAlarmTime(alarm);
    if (alarmTime == null) {
      debugPrint('알람 예약 실패: 다음 알람 시간을 계산할 수 없음');
      return;
    }

    debugPrint('알람 예약: 다음 알람 시간 계산됨 - ${alarmTime.toString()}');

    // 고유한 알람 ID 생성 (단순화)
    int uniqueId = alarm.id * 10000 + (alarm.time.hour * 100 + alarm.time.minute);
    int safeId = uniqueId % 1000000; // 32비트 정수 범위 내로 제한

    debugPrint('알람 예약: 생성된 안전한 ID - $safeId');

    // 기존에 같은 ID로 예약된 알람이 있다면 취소
    try {
      await AndroidAlarmManager.cancel(safeId);
      debugPrint('알람 예약: 기존 알람 취소 완료');
    } catch (e) {
      debugPrint('알람 예약: 기존 알람 취소 중 오류 (무시): $e');
    }

    // 알람 데이터 저장 (콜백에서 사용)
    debugPrint('알람 예약: SharedPreferences에 데이터 저장 시작');
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
      'setAt': DateTime.now().toString(),
      'safeId': safeId,
    };

    await prefs.setString('alarm_data_$safeId', jsonEncode(alarmData));
    debugPrint('알람 예약: 데이터 저장 완료');

    // 현재 시간과 알람 시간 계산
    final now = DateTime.now();
    final alarmDateTime = DateTime(
      alarmTime.year,
      alarmTime.month,
      alarmTime.day,
      alarm.time.hour,
      alarm.time.minute,
      0, // 초는 0으로 설정
    );

    debugPrint('알람 예약: 현재 시간 - ${now.toString()}');
    debugPrint('알람 예약: 예약할 시간 - ${alarmDateTime.toString()}');

    // 이미 지난 시간이면 다음날로 설정
    DateTime finalAlarmTime = alarmDateTime;
    if (alarmDateTime.isBefore(now.add(const Duration(seconds: 10)))) {
      finalAlarmTime = alarmDateTime.add(const Duration(days: 1));
      debugPrint('알람 예약: 이미 지난 시간이므로 다음날로 설정 - ${finalAlarmTime.toString()}');
    }

    // 안드로이드 알람 매니저로 예약 (단순화된 버전)
    debugPrint('알람 예약: AndroidAlarmManager.oneShotAt 호출');

    final success = await AndroidAlarmManager.oneShotAt(
      finalAlarmTime,
      safeId,
      alarmCallback, // main.dart의 간소화된 alarmCallback 사용
      exact: true,
      wakeup: true,
      alarmClock: true,
      rescheduleOnReboot: true,
    );

    if (success) {
      // 성공 시 최종 데이터 업데이트
      alarmData['scheduledTime'] = finalAlarmTime.toString();
      alarmData['scheduledAt'] = DateTime.now().toString();
      await prefs.setString('alarm_data_$safeId', jsonEncode(alarmData));

      final triggerInSeconds = finalAlarmTime.difference(now).inSeconds;
      debugPrint('알람 예약 성공: ID=$safeId, ${triggerInSeconds}초 후 울림');
      debugPrint('======== 알람 예약 완료 ========');
    } else {
      debugPrint('알람 예약 실패: ID=$safeId');
    }
  }

  // 알람 취소
  Future<void> cancelAlarm(Alarm alarm) async {
    debugPrint('======== 알람 취소 시작: ID=${alarm.id} ========');

    // 모든 가능한 변형 ID로 취소 시도
    await _cancelAllVariationsOfAlarm(alarm);

    debugPrint('======== 알람 취소 완료: ID=${alarm.id} ========');
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

  // 알람음 재생 - 화면 표시 기능 추가
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