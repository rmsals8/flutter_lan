import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/alarm.dart';

class AlarmService {
  static final AlarmService _instance = AlarmService._internal();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  // 싱글톤 패턴
  factory AlarmService() => _instance;
  
  AlarmService._internal();

  Future<void> initialize() async {
    if (_isInitialized) return;

    // 타임존 초기화
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Seoul'));

    // 안드로이드 설정
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS 설정 (flutter_local_notifications 19.2.1 버전 호환)
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

    _isInitialized = true;
  }

  // 알림 응답 처리 콜백
  void onDidReceiveNotificationResponse(NotificationResponse response) {
    debugPrint('알림 응답: ${response.payload}');
    // 실제 앱에서는 여기서 알림 탭 시 처리를 구현
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
  }

  // 알람 예약
  Future<void> scheduleAlarm(Alarm alarm) async {
    await initialize();

    final alarmTime = _calculateNextAlarmTime(alarm);
    if (alarmTime == null) return;

    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'alarm_channel',
      '알람',
      channelDescription: '알람 알림 채널',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidNotificationDetails);

    // 최신 버전의 flutter_local_notifications API에 맞게 수정
    // uiLocalNotificationDateInterpretation 매개변수 제거
    await flutterLocalNotificationsPlugin.zonedSchedule(
      alarm.id,
      alarm.label,
      '알람 시간입니다',
      tz.TZDateTime.from(alarmTime, tz.local),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: alarm.soundPath,
    );
  }
  
  // 알람 취소
  Future<void> cancelAlarm(Alarm alarm) async {
    await flutterLocalNotificationsPlugin.cancel(alarm.id);
  }
  
  // 모든 알람 취소
  Future<void> cancelAllAlarms() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  // 알람음 재생 (실제로는 just_audio 등의 패키지를 사용)
  Future<void> playAlarmSound(String soundPath) async {
    // 이 부분은 just_audio 등의 패키지를 사용하여 구현
    debugPrint('알람음 재생: $soundPath');
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
}