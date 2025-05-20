// lib/services/alarm_service.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import '../models/alarm.dart';
import 'package:just_audio/just_audio.dart';

class AlarmService {
  static final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static final AudioPlayer _audioPlayer = AudioPlayer();
  static bool _isInitialized = false;
  
  // 싱글톤 패턴
  static final AlarmService _instance = AlarmService._internal();
  
  factory AlarmService() => _instance;
  
  AlarmService._internal();

  // 알람 초기화
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    // 타임존 초기화
    tz.initializeTimeZones();
    // 한국 시간대 고정 사용
    tz.setLocalLocation(tz.getLocation('Asia/Seoul'));
    
    // 안드로이드 알람 매니저 초기화
    await AndroidAlarmManager.initialize();
    
    // 로컬 알림 초기화
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    final DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      onDidReceiveLocalNotification: (id, title, body, payload) async {
        // 알림 받았을 때 처리 로직
      },
    );
    
    final InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        // 알림 클릭 처리
      },
    );
    
    _isInitialized = true;
  }
  
  // 알람 저장
  Future<void> saveAlarms(List<Alarm> alarms) async {
    final prefs = await SharedPreferences.getInstance();
    final alarmsJson = alarms.map((alarm) => jsonEncode(alarm.toJson())).toList();
    await prefs.setStringList('alarms', alarmsJson);
  }
  
  // 알람 불러오기
  Future<List<Alarm>> loadAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final alarmsJson = prefs.getStringList('alarms') ?? [];
    
    return alarmsJson
        .map((alarmJson) => Alarm.fromJson(jsonDecode(alarmJson)))
        .toList();
  }
  
  // 알람 추가
  Future<void> addAlarm(Alarm alarm) async {
    final alarms = await loadAlarms();
    alarms.add(alarm);
    await saveAlarms(alarms);
    
    if (alarm.isEnabled) {
      await scheduleAlarm(alarm);
    }
  }
  
  // 알람 수정
  Future<void> updateAlarm(Alarm alarm) async {
    final alarms = await loadAlarms();
    final index = alarms.indexWhere((a) => a.id == alarm.id);
    
    if (index != -1) {
      // 기존 알람 취소
      await cancelAlarm(alarms[index]);
      
      // 알람 업데이트
      alarms[index] = alarm;
      await saveAlarms(alarms);
      
      // 활성화된 경우 다시 예약
      if (alarm.isEnabled) {
        await scheduleAlarm(alarm);
      }
    }
  }
  
  // 알람 삭제
  Future<void> deleteAlarm(int alarmId) async {
    final alarms = await loadAlarms();
    final alarm = alarms.firstWhere((a) => a.id == alarmId, orElse: () => null as Alarm);
    
    if (alarm != null) {
      await cancelAlarm(alarm);
      alarms.removeWhere((a) => a.id == alarmId);
      await saveAlarms(alarms);
    }
  }
  
  // 알람 예약
  Future<void> scheduleAlarm(Alarm alarm) async {
    await initialize();
    
    final alarmTime = _calculateNextAlarmTime(alarm);
    if (alarmTime == null) return;
    
    // 안드로이드 알람 매니저로 정확한 시간에 알람 예약
    await AndroidAlarmManager.oneShotAt(
      alarmTime,
      alarm.id,
      _alarmCallback,
      exact: true,
      wakeup: true,
      rescheduleOnReboot: true,
      params: {'alarmId': alarm.id},
    );
    
    // 로컬 알림으로도 예약 (백업 용도)
    final androidDetails = AndroidNotificationDetails(
      'alarm_channel',
      '알람',
      channelDescription: '알람 알림 채널',
      importance: Importance.max,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound('alarm_sound'),
      largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
    );
    
    final iosDetails = DarwinNotificationDetails(
      sound: 'alarm_sound.mp3',
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    // TZDateTime 객체 생성 (고정 시간대 사용)
    final scheduledTime = tz.TZDateTime.from(alarmTime, tz.local);
    
    await _flutterLocalNotificationsPlugin.zonedSchedule(
      alarm.id,
      alarm.label,
      '알람 시간입니다',
      scheduledTime,
      notificationDetails,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: _getDateTimeComponents(alarm),
    );
  }
  
  // 알람 취소
  Future<void> cancelAlarm(Alarm alarm) async {
    await AndroidAlarmManager.cancel(alarm.id);
    await _flutterLocalNotificationsPlugin.cancel(alarm.id);
  }
  
  // 알람 음악 재생
  Future<void> playAlarmSound(String soundPath) async {
    try {
      await _audioPlayer.setFilePath(soundPath);
      await _audioPlayer.setLoopMode(LoopMode.all);
      await _audioPlayer.play();
    } catch (e) {
      debugPrint('알람 재생 오류: $e');
      // 기본 알람음 재생
      await _audioPlayer.setAsset('assets/default_alarm.mp3');
      await _audioPlayer.setLoopMode(LoopMode.all);
      await _audioPlayer.play();
    }
  }
  
  // 알람 음악 정지
  Future<void> stopAlarmSound() async {
    await _audioPlayer.stop();
  }
  
  // 다음 알람 시간 계산
  DateTime? _calculateNextAlarmTime(Alarm alarm) {
    final now = DateTime.now();
    final today = now.weekday - 1; // 0(월) ~ 6(일)
    
    // 반복 없는 경우
    if (!alarm.repeatDays.contains(true)) {
      final alarmTime = DateTime(
        now.year,
        now.month,
        now.day,
        alarm.time.hour,
        alarm.time.minute,
      );
      
      // 이미 지난 시간이면 내일로 설정
      if (alarmTime.isBefore(now)) {
        return alarmTime.add(const Duration(days: 1));
      }
      return alarmTime;
    }
    
    // 요일 반복이 있는 경우
    for (int i = 0; i < 7; i++) {
      final dayToCheck = (today + i) % 7;
      if (alarm.repeatDays[dayToCheck]) {
        final daysToAdd = i == 0 && now.hour > alarm.time.hour ? 7 : i;
        final alarmTime = DateTime(
          now.year,
          now.month,
          now.day + daysToAdd,
          alarm.time.hour,
          alarm.time.minute,
        );
        
        if (alarmTime.isAfter(now)) {
          return alarmTime;
        }
      }
    }
    
    return null;
  }
  
  // 알람 반복 설정
  DateTimeComponents? _getDateTimeComponents(Alarm alarm) {
    if (!alarm.repeatDays.contains(true)) {
      return null;
    }
    
    return DateTimeComponents.dayOfWeekAndTime;
  }
  
  // 알람 콜백 (백그라운드에서 실행)
  @pragma('vm:entry-point')
  static void _alarmCallback(int id, Map<String, dynamic>? params) async {
    // 이 메서드는 isolate에서 실행되므로 UI와 관련된 코드는 실행할 수 없음
    final service = AlarmService();
    final alarms = await service.loadAlarms();
    
    try {
      final alarmId = params != null && params.containsKey('alarmId') 
          ? params['alarmId'] as int 
          : id;
          
      final alarm = alarms.firstWhere(
        (a) => a.id == alarmId,
        orElse: () => null as Alarm,
      );
      
      if (alarm != null && alarm.isEnabled) {
        // 알람음 재생
        await service.playAlarmSound(alarm.soundPath);
        
        // 알람이 반복 설정이 아니면 비활성화
        if (!alarm.repeatDays.contains(true)) {
          // 새 객체 생성해서 업데이트 (final 변수 수정 오류 방지)
          final updatedAlarm = alarm.copyWith(isEnabled: false);
          await service.updateAlarm(updatedAlarm);
        } else {
          // 다음 알람 예약
          await service.scheduleAlarm(alarm);
        }
      }
    } catch (e) {
      debugPrint('알람 콜백 오류: $e');
    }
  }
}