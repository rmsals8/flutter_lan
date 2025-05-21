// lib/services/alarm_receiver.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:io';

// 알람 콜백용 독립적인 클래스
class AlarmReceiver {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = 
      FlutterLocalNotificationsPlugin();
  static final AudioPlayer _audioPlayer = AudioPlayer();
  
  // 알람 콜백 (vm:entry-point 어노테이션 필수)
  @pragma('vm:entry-point')
  static Future<void> onAlarm(int id) async {
    debugPrint('AlarmReceiver.onAlarm 실행: ID=$id');
    
    // 알림 초기화
    await _initializeNotifications();
    
    // SharedPreferences에서 알람 정보 가져오기
    final prefs = await SharedPreferences.getInstance();
    final alarmJson = prefs.getString('alarm_data_$id');
    
    if (alarmJson != null) {
      try {
        final alarmMap = jsonDecode(alarmJson) as Map<String, dynamic>;
        final label = alarmMap['label'] as String? ?? '알람';
        final soundPath = alarmMap['soundPath'] as String? ?? 'assets/default_alarm.mp3';
        
        // 알림 표시
        await _showNotification(
          id: id,
          title: label,
          body: '알람 시간입니다',
          payload: soundPath,
        );
        
        // 알람음 재생
        await _playAlarmSound(soundPath);
        
        debugPrint('알람 성공적으로 표시됨: ID=$id, Label=$label');
      } catch (e) {
        debugPrint('알람 데이터 파싱 오류: $e');
        
        // 기본 알림 표시
        await _showNotification(
          id: id,
          title: '알람',
          body: '알람 시간입니다',
        );
      }
    } else {
      debugPrint('알람 데이터를 찾을 수 없음: ID=$id');
      
      // 알람 데이터가 없는 경우 기본 알림 표시
      await _showNotification(
        id: id,
        title: '알람',
        body: '알람 시간입니다',
      );
    }
  }
  
  // 알림 초기화
  @pragma('vm:entry-point')
  static Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    final DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings();
    
    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );
    
    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );
  }
  
  // 알림 응답 처리
  @pragma('vm:entry-point')
  static void _onNotificationResponse(NotificationResponse response) {
    debugPrint('알림 응답: ${response.payload}');
    
    if (response.payload != null && response.payload!.isNotEmpty) {
      _playAlarmSound(response.payload!);
    } else {
      _playAlarmSound('assets/default_alarm.mp3');
    }
  }
  
  // 알림 표시
  @pragma('vm:entry-point')
  static Future<void> _showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
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
    
    await _notificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }
  
  // 알람음 재생
  @pragma('vm:entry-point')
  static Future<void> _playAlarmSound(String soundPath) async {
    try {
      debugPrint('알람음 재생 시도: $soundPath');
      
      await _audioPlayer.stop();
      
     // lib/services/alarm_receiver.dart (계속)
      if (soundPath.startsWith('assets/')) {
        // 앱 에셋 파일
        await _audioPlayer.setAsset(soundPath);
      } else if (soundPath.startsWith('file://')) {
        // 로컬 파일 (file:// 프로토콜 사용)
        final path = soundPath.replaceFirst('file://', '');
        await _audioPlayer.setFilePath(path);
      } else if (soundPath.isNotEmpty && File(soundPath).existsSync()) {
        // 일반 로컬 파일 경로
        await _audioPlayer.setFilePath(soundPath);
      } else {
        // 기본 알람음으로 폴백
        await _audioPlayer.setAsset('assets/default_alarm.mp3');
      }
      
      // 루프 재생 설정
      await _audioPlayer.setLoopMode(LoopMode.one);
      // 볼륨 최대로 설정
      await _audioPlayer.setVolume(1.0);
      
      // 재생 시작
      await _audioPlayer.play();
    } catch (e) {
      debugPrint('알람음 재생 오류: $e');
      
      // 오류 발생 시 기본 알람음으로 폴백
      try {
        await _audioPlayer.setAsset('assets/default_alarm.mp3');
        await _audioPlayer.setLoopMode(LoopMode.one);
        await _audioPlayer.setVolume(1.0);
        await _audioPlayer.play();
      } catch (fallbackError) {
        debugPrint('기본 알람음 재생 오류: $fallbackError');
      }
    }
  }
  
  // 알람음 정지
  @pragma('vm:entry-point')
  static Future<void> stopAlarmSound() async {
    try {
      await _audioPlayer.stop();
    } catch (e) {
      debugPrint('알람음 정지 오류: $e');
    }
  }
}