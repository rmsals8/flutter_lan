// lib/services/alarm_receiver.dart
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data'; // Int64List를 사용하기 위해 추가
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:io';
import '../main.dart'; // main.dart에서 navigatorKey를 import
import '../models/alarm.dart';

// 알람 콜백용 독립적인 클래스
class AlarmReceiver {
  // 플레이어 객체를 유지하기 위한 정적 변수
  static AudioPlayer? _keepAlivePlayer;

  // 알람 콜백 (vm:entry-point 어노테이션 필수)
  @pragma('vm:entry-point')
  static Future<void> onAlarm(int id) async {
    debugPrint('======== 알람 시작: ID=$id, 시간=${DateTime.now()} ========');

    try {
      // 1. 알람음 재생 (가장 먼저)
      await _playSound('assets/default_alarm.mp3');

      // 2. 전체화면 알람 화면 표시 (가장 중요한 부분)
      await _showFullScreenAlarm(id);

      // 3. 백업용 알림도 표시
      await _showAlarmNotification(id);

    } catch (e) {
      debugPrint('알람: 전체 프로세스 오류: $e');

      // 마지막 수단으로 소리 재생 시도
      try {
        final lastPlayer = AudioPlayer();
        await lastPlayer.setAsset('assets/default_alarm.mp3');
        await lastPlayer.setVolume(1.0);
        await lastPlayer.play();
        debugPrint('알람: 백업 소리 재생 시작');
      } catch (finalError) {
        debugPrint('알람: 모든 소리 재생 시도 실패: $finalError');
      }
    }
  }

  // 전체화면 알람을 표시하는 새로운 기능 (가장 중요!)
  static Future<void> _showFullScreenAlarm(int id) async {
    try {
      debugPrint('알람: 전체화면 알람 표시 시도 - ID: $id');

      // SharedPreferences에서 알람 정보 가져오기
      final prefs = await SharedPreferences.getInstance();
      final alarmJson = prefs.getString('alarm_data_$id');

      Alarm alarm;
      if (alarmJson != null) {
        try {
          final Map<String, dynamic> alarmMap = jsonDecode(alarmJson);
          alarm = Alarm(
            id: alarmMap['id'] ?? id,
            time: TimeOfDay(
              hour: alarmMap['hour'] ?? TimeOfDay.now().hour,
              minute: alarmMap['minute'] ?? TimeOfDay.now().minute,
            ),
            repeatDays: List<bool>.from(alarmMap['repeatDays'] ?? List.filled(7, false)),
            label: alarmMap['label'] ?? '알람',
            soundPath: alarmMap['soundPath'] ?? 'assets/default_alarm.mp3',
            soundName: alarmMap['soundName'] ?? '기본 알람음',
            isEnabled: true,
          );
          debugPrint('알람: 저장된 알람 데이터 로드 성공');
        } catch (e) {
          debugPrint('알람: 저장된 데이터 파싱 오류: $e');
          alarm = _createDefaultAlarm(id);
        }
      } else {
        debugPrint('알람: 저장된 데이터 없음, 기본 알람 생성');
        alarm = _createDefaultAlarm(id);
      }

      // 전체화면 intent 알림 생성 (앱이 꺼져있어도 깨우는 기능)
      await _showFullScreenIntent(id, alarm);

      // 앱이 실행 중이면 직접 화면 표시
      if (navigatorKey.currentContext != null) {
        debugPrint('알람: 앱이 실행 중, 직접 알람 화면으로 이동');

        // 잠시 기다린 후 알람 화면으로 이동
        await Future.delayed(const Duration(milliseconds: 300));

        navigatorKey.currentState?.pushNamedAndRemoveUntil(
          '/alarm-ringing',
              (route) => false, // 모든 이전 화면 제거
          arguments: {'alarm': alarm},
        );
      } else {
        debugPrint('알람: 앱이 실행되지 않음, fullScreenIntent로 앱 깨우기');
      }

    } catch (e) {
      debugPrint('알람: 전체화면 알람 표시 오류: $e');
    }
  }

  // 기본 알람 생성 기능
  static Alarm _createDefaultAlarm(int id) {
    final now = DateTime.now();
    return Alarm(
      id: id,
      time: TimeOfDay(hour: now.hour, minute: now.minute),
      repeatDays: List.filled(7, false),
      label: '알람',
      soundPath: 'assets/default_alarm.mp3',
      soundName: '기본 알람음',
      isEnabled: true,
    );
  }

  // 전체화면 Intent 알림 (앱을 깨우고 화면을 켜는 기능)
  static Future<void> _showFullScreenIntent(int id, Alarm alarm) async {
    try {
      debugPrint('알람: 전체화면 Intent 알림 생성 시작');

      final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();

      // 알림 초기화
      const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

      final DarwinInitializationSettings initializationSettingsDarwin =
      DarwinInitializationSettings();

      final InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsDarwin,
      );

      await notificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('알람: 알림 응답 수신: ${response.payload}');

          // 알림을 탭했을 때 알람 화면 표시
          if (response.payload != null && response.payload!.contains('alarm_')) {
            _handleNotificationTap(response.payload!, alarm);
          }
        },
      );

      // 전체화면 알림 채널 생성
      const AndroidNotificationChannel fullScreenChannel = AndroidNotificationChannel(
        'alarm_fullscreen_channel',
        '전체화면 알람',
        description: '전체화면으로 표시되는 알람',
        importance: Importance.max,
        enableVibration: true,
        enableLights: true,
        playSound: false, // 우리가 직접 소리를 재생하므로 false
      );

      await notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(fullScreenChannel);

      // 전체화면 알림 세부사항 (핵심: fullScreenIntent = true)
      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'alarm_fullscreen_channel',
        '전체화면 알람',
        channelDescription: '전체화면으로 표시되는 알람',
        importance: Importance.max,
        priority: Priority.high,
        fullScreenIntent: true, // 가장 중요한 부분!
        visibility: NotificationVisibility.public,
        category: AndroidNotificationCategory.alarm,
        ongoing: true,
        autoCancel: false,
        showWhen: true,
        when: DateTime.now().millisecondsSinceEpoch,
        enableVibration: true,
        enableLights: true,
        ledColor: const Color(0xFF3498DB),
        ledOnMs: 1000,
        ledOffMs: 500,
        sound: null, // 소리는 직접 재생
        playSound: false,
        // 화면을 켜고 잠금을 해제하는 추가 옵션들
        usesChronometer: false,
        timeoutAfter: 60000, // 60초 후 자동 타임아웃
      );

      final NotificationDetails details = NotificationDetails(android: androidDetails);

      // 전체화면 알림 표시
      await notificationsPlugin.show(
        id,
        '⏰ ${alarm.label}',
        '알람 시간입니다! ${alarm.readableTime}',
        details,
        payload: 'alarm_fullscreen_$id',
      );

      debugPrint('알람: 전체화면 Intent 알림 표시 완료');

    } catch (e) {
      debugPrint('알람: 전체화면 Intent 알림 오류: $e');
    }
  }

  // 알림 탭 처리 기능
  static void _handleNotificationTap(String payload, Alarm alarm) {
    try {
      debugPrint('알람: 알림 탭 처리 시작: $payload');

      // 앱이 실행 중이면 알람 화면으로 이동
      if (navigatorKey.currentContext != null) {
        navigatorKey.currentState?.pushNamedAndRemoveUntil(
          '/alarm-ringing',
              (route) => false,
          arguments: {'alarm': alarm},
        );
      }
    } catch (e) {
      debugPrint('알람: 알림 탭 처리 오류: $e');
    }
  }

  // 일반 알림 표시 기능 (백업용)
  static Future<void> _showAlarmNotification(int id) async {
    debugPrint('알람: 백업 알림 표시 시작');

    try {
      final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();

      // 일반 알림 채널
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'alarm_backup_channel',
        '백업 알람',
        description: '백업용 알람 알림',
        importance: Importance.high,
        enableVibration: true,
        playSound: false,
      );

      await notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      // 백업 알림 세부사항
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'alarm_backup_channel',
        '백업 알람',
        channelDescription: '백업용 알람 알림',
        importance: Importance.high,
        priority: Priority.high,
        visibility: NotificationVisibility.public,
        category: AndroidNotificationCategory.alarm,
        ongoing: true,
        autoCancel: false,
      );

      const NotificationDetails details = NotificationDetails(android: androidDetails);

      // SharedPreferences에서 알람 정보 가져오기
      final prefs = await SharedPreferences.getInstance();
      final alarmJson = prefs.getString('alarm_data_$id');

      String alarmTitle = '알람';
      if (alarmJson != null) {
        try {
          final Map<String, dynamic> alarmMap = jsonDecode(alarmJson);
          alarmTitle = alarmMap['label'] as String? ?? '알람';
        } catch (e) {
          debugPrint('알람: 백업 알림 데이터 파싱 오류: $e');
        }
      }

      // 백업 알림 표시
      await notificationsPlugin.show(
        id + 1000, // 다른 ID 사용
        alarmTitle,
        '알람 시간입니다!',
        details,
        payload: 'alarm_backup_$id',
      );

      debugPrint('알람: 백업 알림 표시 성공');
    } catch (e) {
      debugPrint('알람: 백업 알림 표시 오류: $e');
    }
  }

  // 알람음 재생 - 단순화된 버전
  static Future<void> _playSound(String soundPath) async {
    debugPrint('알람: _playSound 메서드 시작 - 경로: $soundPath');

    try {
      // 1. 이전 플레이어 정리
      if (_keepAlivePlayer != null) {
        debugPrint('알람: 이전 플레이어 정리');
        await _keepAlivePlayer!.stop();
        await _keepAlivePlayer!.dispose();
        _keepAlivePlayer = null;
      }

      // 2. 새 플레이어 생성
      debugPrint('알람: 새 AudioPlayer 생성');
      final player = AudioPlayer();

      // 3. 볼륨 최대화
      debugPrint('알람: 볼륨 설정 시도');
      await player.setVolume(1.0);
      debugPrint('알람: 볼륨 설정 완료: ${player.volume}');

      // 4. 에셋 로드
      debugPrint('알람: 에셋 로드 시도: assets/default_alarm.mp3');
      await player.setAsset('assets/default_alarm.mp3');
      debugPrint('알람: 에셋 로드 완료');

      // 5. 루프 모드 설정 (재생 전에 설정)
      debugPrint('알람: 루프 모드 설정 시도');
      await player.setLoopMode(LoopMode.one);
      debugPrint('알람: 루프 모드 설정 완료');

      // 6. 재생 시작
      debugPrint('알람: 재생 시작 시도');
      await player.play();
      debugPrint('알람: 재생 시작 완료 - 재생 중: ${player.playing}');

      // 7. 소리가 계속 재생되도록 정적 변수에 보관
      _keepAlivePlayer = player;
      debugPrint('알람: 플레이어 참조 저장 완료');

      // 8. 재생 상태 모니터링
      player.playerStateStream.listen((state) {
        debugPrint('알람: 플레이어 상태 - ${state.processingState}, 재생중: ${state.playing}');

        // 만약 재생이 멈추면 다시 시작
        if (state.processingState == ProcessingState.completed && _keepAlivePlayer != null) {
          debugPrint('알람: 재생 완료됨, 다시 시작');
          _keepAlivePlayer!.seek(Duration.zero);
          _keepAlivePlayer!.play();
        }
      });

    } catch (e) {
      debugPrint('알람: 소리 재생 오류 발생: $e');
      _playBackupSound();
    }
  }

  // 백업 재생 메서드
  static Future<void> _playBackupSound() async {
    debugPrint('알람: _playBackupSound 메서드 시작');

    try {
      debugPrint('알람: 백업 AudioPlayer 생성');
      final backupPlayer = AudioPlayer();

      debugPrint('알람: 백업 - 에셋 로드 시도');
      await backupPlayer.setAsset('assets/default_alarm.mp3');
      debugPrint('알람: 백업 - 에셋 로드 완료');

      debugPrint('알람: 백업 - 볼륨 설정 시도');
      await backupPlayer.setVolume(1.0);
      debugPrint('알람: 백업 - 볼륨 설정 완료');

      debugPrint('알람: 백업 - 루프 모드 설정 시도');
      await backupPlayer.setLoopMode(LoopMode.one);
      debugPrint('알람: 백업 - 루프 모드 설정 완료');

      debugPrint('알람: 백업 - 재생 시작 시도');
      await backupPlayer.play();
      debugPrint('알람: 백업 - 재생 시작 완료');

      _keepAlivePlayer = backupPlayer;
      debugPrint('알람: 백업 - 플레이어 참조 저장 완료');
    } catch (e) {
      debugPrint('알람: 백업 소리 재생 오류: $e');
    }
  }

  // 알람음 중지 기능 (외부에서 호출 가능)
  static Future<void> stopAlarmSound() async {
    try {
      if (_keepAlivePlayer != null) {
        debugPrint('알람: 알람음 중지 시도');
        await _keepAlivePlayer!.stop();
        await _keepAlivePlayer!.dispose();
        _keepAlivePlayer = null;
        debugPrint('알람: 알람음 중지 완료');
      }
    } catch (e) {
      debugPrint('알람: 알람음 중지 오류: $e');
    }
  }
}