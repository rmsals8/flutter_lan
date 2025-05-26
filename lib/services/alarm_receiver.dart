// lib/services/alarm_receiver.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:io';
import '../main.dart'; // main.dart에서 navigatorKey를 import

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

      // 2. 알림 표시
      await _showAlarmNotification(id);

      // 3. 앱을 깨우고 알람 화면 표시
      await _wakeUpAppAndShowAlarmScreen(id);

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

  // 앱을 깨우고 알람 화면을 표시하는 기능
  static Future<void> _wakeUpAppAndShowAlarmScreen(int id) async {
    try {
      debugPrint('알람: 앱 깨우기 및 알람 화면 표시 시도');

      // SharedPreferences에서 알람 정보 가져오기
      final prefs = await SharedPreferences.getInstance();
      final alarmJson = prefs.getString('alarm_data_$id');

      if (alarmJson != null) {
        final Map<String, dynamic> alarmMap = jsonDecode(alarmJson);

        // 알람 객체 생성
        final alarm = _createAlarmFromMap(alarmMap);

        // 앱 깨우기 알림 (fullScreenIntent 사용)
        await _showWakeUpNotification(id, alarm);

        // 앱이 실행 중이고 네비게이터가 준비되어 있다면 화면 표시
        if (navigatorKey.currentContext != null) {
          debugPrint('알람: 앱이 실행 중임, 알람 화면으로 이동');

          // 잠시 기다린 후 알람 화면으로 이동
          await Future.delayed(const Duration(milliseconds: 500));

          navigatorKey.currentState?.pushNamed(
            '/alarm-ringing',
            arguments: {'alarm': alarm},
          );
        } else {
          debugPrint('알람: 앱이 실행되지 않음, fullScreenIntent 알림으로 앱 깨우기');
        }
      }
    } catch (e) {
      debugPrint('알람: 앱 깨우기 및 화면 표시 오류: $e');
    }
  }

  // 앱을 깨우는 전체 화면 알림
  static Future<void> _showWakeUpNotification(int id, dynamic alarm) async {
    try {
      debugPrint('알람: 앱 깨우기 알림 표시 시작');

      final FlutterLocalNotificationsPlugin notificationsPlugin = FlutterLocalNotificationsPlugin();

      // 알림 초기화
      const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

      final DarwinInitializationSettings initializationSettingsDarwin =
      DarwinInitializationSettings();

      final InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsDarwin,
      );

      await notificationsPlugin.initialize(initializationSettings);

      // Android 알림 채널 설정
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'alarm_wakeup_channel',
        '알람 깨우기',
        description: '앱을 깨우는 알람 채널',
        importance: Importance.max,
        enableVibration: true,
        playSound: false,
      );

      // 채널 생성
      await notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      // 전체 화면 알림 세부 사항 (앱을 깨우는 용도)
      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'alarm_wakeup_channel',
        '알람 깨우기',
        channelDescription: '앱을 깨우는 알람 채널',
        importance: Importance.max,
        priority: Priority.high,
        fullScreenIntent: true, // 전체 화면으로 앱 깨우기
        visibility: NotificationVisibility.public,
        category: AndroidNotificationCategory.alarm,
        sound: null,
        playSound: false,
        ongoing: true,
        autoCancel: false,
        showWhen: true,
        when: DateTime.now().millisecondsSinceEpoch,
        usesChronometer: false,
        enableVibration: true,
        enableLights: true,
        ledColor: const Color(0xFF3498DB),
        ledOnMs: 1000,
        ledOffMs: 500,
      );

      final NotificationDetails details = NotificationDetails(android: androidDetails);

      final String alarmTitle = alarm['label'] ?? '알람';

      // 앱 깨우기 알림 표시
      await notificationsPlugin.show(
        id + 10000, // 다른 ID 사용 (중복 방지)
        '⏰ $alarmTitle',
        '알람 시간입니다! 탭해서 알람을 끄세요.',
        details,
        payload: 'alarm_wakeup_$id',
      );

      debugPrint('알람: 앱 깨우기 알림 표시 성공: ID=${id + 10000}');
    } catch (e) {
      debugPrint('알람: 앱 깨우기 알림 표시 오류: $e');
    }
  }

  // Map에서 Alarm 객체 생성
  static dynamic _createAlarmFromMap(Map<String, dynamic> alarmMap) {
    return {
      'id': alarmMap['id'] ?? 0,
      'label': alarmMap['label'] ?? '알람',
      'soundPath': alarmMap['soundPath'] ?? 'assets/default_alarm.mp3',
      'soundName': alarmMap['soundName'] ?? '기본 알람음',
      'hour': alarmMap['hour'] ?? 7,
      'minute': alarmMap['minute'] ?? 0,
    };
  }

  // 일반 알림 표시 기능
  static Future<void> _showAlarmNotification(int id) async {
    debugPrint('알람: 일반 알림 표시 시작');

    try {
      final FlutterLocalNotificationsPlugin notificationsPlugin = FlutterLocalNotificationsPlugin();

      // 알림 초기화
      const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

      final DarwinInitializationSettings initializationSettingsDarwin =
      DarwinInitializationSettings();

      final InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsDarwin,
      );

      await notificationsPlugin.initialize(initializationSettings);

      // Android 알림 채널 설정
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'alarm_channel',
        '알람',
        description: '알람 알림 채널',
        importance: Importance.max,
        enableVibration: true,
        playSound: false,
      );

      // 채널 생성
      await notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      // 일반 알림 세부 사항
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'alarm_channel',
        '알람',
        channelDescription: '알람 알림 채널',
        importance: Importance.max,
        priority: Priority.high,
        visibility: NotificationVisibility.public,
        category: AndroidNotificationCategory.alarm,
        sound: null,
        playSound: false,
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
          debugPrint('알람: 데이터 파싱 오류: $e');
        }
      }

      // 일반 알림 표시
      await notificationsPlugin.show(
        id,
        alarmTitle,
        '알람 시간입니다!',
        details,
        payload: 'alarm_$id',
      );

      debugPrint('알람: 일반 알림 표시 성공: ID=$id');
    } catch (e) {
      debugPrint('알람: 일반 알림 표시 오류: $e');
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

      // 5. 재생 시작
      debugPrint('알람: 재생 시작 시도');
      await player.play();
      debugPrint('알람: 재생 시작 완료 - 재생 중: ${player.playing}');

      // 6. 계속 재생되도록 함
      debugPrint('알람: 루프 모드 설정 시도');
      await player.setLoopMode(LoopMode.one);
      debugPrint('알람: 루프 모드 설정 완료');

      // 7. 소리가 계속 재생되도록 정적 변수에 보관
      _keepAlivePlayer = player;
      debugPrint('알람: 플레이어 참조 저장 완료');

      // 8. 재생 상태 디버깅
      player.playerStateStream.listen((state) {
        debugPrint('알람: 플레이어 상태 변경 - 상태: ${state.processingState}, 재생 중: ${state.playing}');

        // 완료되면 다시 시작 (루프가 작동하지 않는 경우를 대비)
        if (state.processingState == ProcessingState.completed && _keepAlivePlayer != null) {
          debugPrint('알람: 재생 완료됨, 다시 시작');
          _keepAlivePlayer!.seek(Duration.zero);
          _keepAlivePlayer!.play();
        }
      });

    } catch (e) {
      debugPrint('알람: 소리 재생 오류 발생: $e');
      // 오류 발생 시 백업 방법으로 재생 시도
      debugPrint('알람: 백업 재생 방법 시도');
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
      debugPrint('알람: 백업 - 볼륨 설정 완료: ${backupPlayer.volume}');

      debugPrint('알람: 백업 - 재생 시작 시도');
      await backupPlayer.play();
      debugPrint('알람: 백업 - 재생 시작 완료 - 재생 중: ${backupPlayer.playing}');

      debugPrint('알람: 백업 - 루프 모드 설정 시도');
      await backupPlayer.setLoopMode(LoopMode.one);
      debugPrint('알람: 백업 - 루프 모드 설정 완료');

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