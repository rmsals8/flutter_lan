import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:just_audio/just_audio.dart';

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
  final AudioPlayer _audioPlayer = AudioPlayer();
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
  }
}

  
 // 알람 삭제
Future<void> deleteAlarm(int alarmId) async {
  final alarms = await loadAlarms();
  final alarm = alarms.firstWhere(
    (a) => a.id == alarmId, 
    orElse: () => null as Alarm
  );
  
  if (alarm != null) {
    // 안전한 ID로 알람 취소
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

  // 32비트 정수 범위 내로 ID 제한
  int safeId = alarm.id % 2000000000;

  // 최신 버전의 flutter_local_notifications API에 맞게 수정
  // uiLocalNotificationDateInterpretation 매개변수 제거
  await flutterLocalNotificationsPlugin.zonedSchedule(
    safeId, // 수정된 ID 사용
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
  // ID를 32비트 정수 범위로 제한
  int safeId = alarm.id % 2000000000;
  await flutterLocalNotificationsPlugin.cancel(safeId);
}
  
  // 모든 알람 취소
  Future<void> cancelAllAlarms() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

// playAlarmSound 메서드 수정
Future<void> playAlarmSound(String soundPath) async {
  try {
    debugPrint('알람음 재생 시도: $soundPath');
    
    // 기본 알람음 경로 설정
    String audioPath = 'asset:///assets/default_alarm.mp3';
    
    // 사용자 지정 알람음이 있는 경우
    if (soundPath.isNotEmpty && soundPath != 'assets/default_alarm.mp3') {
      audioPath = soundPath;
    }
    
    // 이전 재생 중지
    await _audioPlayer.stop();
    
    // 알람음 로드 및 재생
    await _audioPlayer.setUrl(audioPath);
    await _audioPlayer.play();
    
    debugPrint('알람음 재생 성공: $audioPath');
  } catch (e) {
    debugPrint('알람음 재생 오류: $e');
    
    // 오류 발생 시 기본 알람음으로 폴백
    try {
      await _audioPlayer.setAsset('assets/default_alarm.mp3');
      await _audioPlayer.play();
    } catch (fallbackError) {
      debugPrint('기본 알람음 재생 오류: $fallbackError');
    }
  }
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