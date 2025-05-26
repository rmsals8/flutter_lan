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
  // 알람 콜백 (vm:entry-point 어노테이션 필수)
  @pragma('vm:entry-point')
  static Future<void> onAlarm(int id) async {
    debugPrint('======== 알람 시작: ID=$id, 시간=${DateTime.now()} ========');
    
    try {
      // 알림 표시 (간소화)
      final FlutterLocalNotificationsPlugin notificationsPlugin = FlutterLocalNotificationsPlugin();
      
      debugPrint('알람: 알림 플러그인 초기화 시작');
      
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
      );
      
      debugPrint('알람: 알림 플러그인 초기화 완료');
      
      // Android 알림 채널 설정 - priority 매개변수 제거
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
      
      debugPrint('알람: 알림 채널 생성 완료');
      
      // 알림 세부 사항 - priority 매개변수를 importance로 대체
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'alarm_channel', 
        '알람', 
        channelDescription: '알람 알림 채널',
        importance: Importance.max,
        fullScreenIntent: true,
        visibility: NotificationVisibility.public,
        category: AndroidNotificationCategory.alarm,
        sound: null, // 알림음은 직접 재생할 것이므로 null로 설정
        playSound: false,
      );
      
      const NotificationDetails details = NotificationDetails(android: androidDetails);
      
      // SharedPreferences에서 알람 정보 가져오기
      debugPrint('알람: SharedPreferences에서 데이터 가져오기 시작');
      final prefs = await SharedPreferences.getInstance();
      final alarmJson = prefs.getString('alarm_data_$id');
      debugPrint('알람: 데이터 조회 결과 - ${alarmJson != null ? "데이터 있음" : "데이터 없음"}');
      
      // 알람 데이터가 있는 경우
      if (alarmJson != null) {
        try {
          final Map<String, dynamic> alarmMap = jsonDecode(alarmJson);
          final String label = alarmMap['label'] as String? ?? '알람';
          final String soundPath = alarmMap['soundPath'] as String? ?? 'assets/default_alarm.mp3';
          
          debugPrint('알람: 데이터 파싱 성공 - 라벨: $label, 소리 경로: $soundPath');
          
          // 알림 표시 시도
          debugPrint('알람: 알림 표시 시도 시작');
          await notificationsPlugin.show(
            id,
            label,
            '알람 시간입니다 (${DateTime.now()})',
            details,
            payload: soundPath,
          );
          
          debugPrint('알람: 알림 표시 성공: ID=$id, Label=$label');
          
          // 알람음 재생 전 짧은 대기 (UI가 표시될 시간 확보)
          await Future.delayed(const Duration(milliseconds: 500));
          
          // 알람음 재생
          debugPrint('알람: 알람음 재생 시도');
          await _playSound(soundPath);
          
          // 알람 시작 로그
          debugPrint('알람: 모든 과정 완료 - 알람 활성화 중');
          
        } catch (e) {
          debugPrint('알람: 데이터 파싱 오류: $e');
          // 기본 알림 표시
          await _showDefaultNotification(notificationsPlugin, id);
        }
      } else {
        debugPrint('알람: 알람 데이터를 찾을 수 없음: ID=$id, 기본 알림 표시');
        // 기본 알림 표시
        await _showDefaultNotification(notificationsPlugin, id);
      }
    } catch (e) {
      debugPrint('알람: 전체 프로세스 오류: $e');
      debugPrint('알람: 백업 알람 소리 재생 시도');
      
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
  
  // 기본 알림 표시 (간소화) - priority 매개변수 제거
  static Future<void> _showDefaultNotification(
    FlutterLocalNotificationsPlugin notificationsPlugin, 
    int id
  ) async {
    debugPrint('알람: 기본 알림 표시 시작');
    
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'alarm_channel', 
      '알람', 
      channelDescription: '알람 알림 채널',
      importance: Importance.max,
      fullScreenIntent: true,
      sound: null, // 알림음은 직접 재생할 것이므로 null로 설정
      playSound: false,
    );
    
    const NotificationDetails details = NotificationDetails(android: androidDetails);
    
    try {
      await notificationsPlugin.show(
        id,
        '알람',
        '알람 시간입니다 (${DateTime.now()})',
        details,
      );
      
      debugPrint('알람: 기본 알림 표시 성공');
      
      // 알람음 재생
      debugPrint('알람: 기본 알람음 재생 시도');
      await _playSound('assets/default_alarm.mp3');
    } catch (e) {
      debugPrint('알람: 기본 알림 표시 오류: $e');
    }
  }
  
  // 플레이어 객체를 유지하기 위한 정적 변수
  static AudioPlayer? _keepAlivePlayer;
  
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
      
      // 9. 오류 리스너 추가
      player.playbackEventStream.listen(
        (event) => debugPrint('알람: 재생 이벤트: $event'),
        onError: (error) => debugPrint('알람: 재생 오류 발생: $error'),
      );
      
      // 10. 추가 확인 - 볼륨이 0인지 확인
      if (player.volume <= 0.01) {
        debugPrint('알람: 경고! 볼륨이 0에 가깝습니다. 볼륨 재설정 시도');
        await player.setVolume(1.0);
      }
      
      // 11. 1초 후 상태 확인
      Future.delayed(const Duration(seconds: 1), () {
        if (_keepAlivePlayer != null) {
          debugPrint('알람: 1초 후 플레이어 상태 - 재생 중: ${_keepAlivePlayer!.playing}, 볼륨: ${_keepAlivePlayer!.volume}');
        } else {
          debugPrint('알람: 1초 후 플레이어 확인 - 플레이어가 null입니다');
        }
      });
      
      // 12. 백업 재생 - 만약 첫 번째 재생이 실패한 경우
      Future.delayed(const Duration(seconds: 2), () {
        if (_keepAlivePlayer == null || _keepAlivePlayer!.playing != true) {
          debugPrint('알람: 2초 후 확인 - 재생이 시작되지 않았습니다. 백업 재생 시도...');
          _playBackupSound();
        } else {
          debugPrint('알람: 2초 후 확인 - 재생 중 정상');
        }
      });
      
    } catch (e) {
      debugPrint('알람: 소리 재생 오류 발생: $e');
      // 오류 발생 시 백업 방법으로 재생 시도
      debugPrint('알람: 백업 재생 방법 시도');
      _playBackupSound();
    }
  }
  
  // 백업 재생 메서드 - 다른 방식으로 시도
  static Future<void> _playBackupSound() async {
    debugPrint('알람: _playBackupSound 메서드 시작');
    
    try {
      debugPrint('알람: 백업 AudioPlayer 생성');
      final backupPlayer = AudioPlayer();
      
      // 에셋 먼저 로드 후 볼륨 설정
      debugPrint('알람: 백업 - 에셋 로드 시도');
      await backupPlayer.setAsset('assets/default_alarm.mp3');
      debugPrint('알람: 백업 - 에셋 로드 완료');
      
      debugPrint('알람: 백업 - 볼륨 설정 시도');
      await backupPlayer.setVolume(1.0);
      debugPrint('알람: 백업 - 볼륨 설정 완료: ${backupPlayer.volume}');
      
      // 재생 시작
      debugPrint('알람: 백업 - 재생 시작 시도');
      await backupPlayer.play();
      debugPrint('알람: 백업 - 재생 시작 완료 - 재생 중: ${backupPlayer.playing}');
      
      // 루프 모드 설정
      debugPrint('알람: 백업 - 루프 모드 설정 시도');
      await backupPlayer.setLoopMode(LoopMode.one);
      debugPrint('알람: 백업 - 루프 모드 설정 완료');
      
      // 글로벌 참조 유지
      _keepAlivePlayer = backupPlayer;
      debugPrint('알람: 백업 - 플레이어 참조 저장 완료');
      
      // 재생 상태 리스너
      backupPlayer.playerStateStream.listen((state) {
        debugPrint('알람: 백업 - 플레이어 상태 변경 - 상태: ${state.processingState}, 재생 중: ${state.playing}');
      });
    } catch (e) {
      debugPrint('알람: 백업 소리 재생 오류: $e');
      
      // 마지막 시도 - 가장 간단한 방법으로 다시 시도
      debugPrint('알람: 마지막 수단 재생 시도');
      try {
        debugPrint('알람: 마지막 AudioPlayer 생성');
        final lastResortPlayer = AudioPlayer();
        
        debugPrint('알람: 마지막 - 에셋 로드 시도');
        await lastResortPlayer.setAsset('assets/default_alarm.mp3');
        debugPrint('알람: 마지막 - 에셋 로드 완료');
        
        debugPrint('알람: 마지막 - 재생 시작 시도');
        await lastResortPlayer.play();
        debugPrint('알람: 마지막 - 재생 시작 완료 - 재생 중: ${lastResortPlayer.playing}');
        
        _keepAlivePlayer = lastResortPlayer;
        debugPrint('알람: 마지막 - 플레이어 참조 저장 완료');
      } catch (finalError) {
        debugPrint('알람: 모든 재생 시도 실패: $finalError');
      }
    }
  }
}