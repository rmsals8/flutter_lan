// lib/services/alarm_receiver.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 추가

// 알람 콜백용 독립적인 클래스 (단순화된 버전)
class AlarmReceiver {
  // 플레이어 객체를 유지하기 위한 정적 변수
  static AudioPlayer? _keepAlivePlayer;

  // 알람 콜백 (단순화된 버전 - 소리만 재생)
  @pragma('vm:entry-point')
  static Future<void> onAlarm(int id) async {
    debugPrint('======== AlarmReceiver.onAlarm 시작: ID=$id ========');

    try {
      // 즉시 트리거 신호 저장 (가장 먼저!)
      await _saveAlarmTriggerDirectly(id);

      // 알람음 재생
      await playAlarmSound();
      debugPrint('AlarmReceiver: 알람음 재생 완료');
    } catch (e) {
      debugPrint('AlarmReceiver: 알람음 재생 오류: $e');

      // 오류가 발생해도 트리거 신호는 저장
      await _saveAlarmTriggerDirectly(id);

      // 백업 재생 시도
      try {
        await _playBackupSound();
      } catch (backupError) {
        debugPrint('AlarmReceiver: 백업 재생도 실패: $backupError');
      }
    }
  }

  // 트리거 신호를 바로 저장하는 함수
  static Future<void> _saveAlarmTriggerDirectly(int alarmId) async {
    try {
      debugPrint('AlarmReceiver: 트리거 신호 즉시 저장 시작 - 실제 알람 ID: $alarmId');

      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();

      // 실제 알람 ID를 그대로 저장
      await prefs.setString('alarm_triggered', alarmId.toString());
      await prefs.setString('alarm_triggered_time', now.toString());

      debugPrint('AlarmReceiver: 트리거 신호 저장 완료 - 저장된 ID: $alarmId');
    } catch (e) {
      debugPrint('AlarmReceiver: 트리거 신호 저장 오류: $e');
    }
  }

  // 알람음 재생 - 알림 표시 추가
  static Future<void> playAlarmSound() async {
    debugPrint('AlarmReceiver: playAlarmSound 시작');

    try {
      // 1. 이전 플레이어 정리
      if (_keepAlivePlayer != null) {
        debugPrint('AlarmReceiver: 이전 플레이어 정리');
        await _keepAlivePlayer!.stop();
        await _keepAlivePlayer!.dispose();
        _keepAlivePlayer = null;
      }

      // 2. 새 플레이어 생성
      debugPrint('AlarmReceiver: 새 AudioPlayer 생성');
      final player = AudioPlayer();

      // 3. 볼륨 최대화
      await player.setVolume(1.0);
      debugPrint('AlarmReceiver: 볼륨 설정 완료');

      // 4. 에셋 로드
      debugPrint('AlarmReceiver: 에셋 로드 시도');
      await player.setAsset('assets/default_alarm.mp3');
      debugPrint('AlarmReceiver: 에셋 로드 완료');

      // 5. 루프 모드 설정
      await player.setLoopMode(LoopMode.one);
      debugPrint('AlarmReceiver: 루프 모드 설정 완료');

      // 6. 재생 시작 (await 제거!)
      debugPrint('AlarmReceiver: 재생 시작 시도');
      player.play(); // await 제거 - 기다리지 않고 바로 다음으로
      debugPrint('AlarmReceiver: 재생 명령 완료');

      // 7. **여기서는 추가 저장하지 않음** (이미 onAlarm에서 저장함)
      debugPrint('AlarmReceiver: 플레이어 트리거 신호는 이미 저장됨');

      // 8. 소리가 계속 재생되도록 정적 변수에 보관
      _keepAlivePlayer = player;
      debugPrint('AlarmReceiver: 플레이어 참조 저장 완료');

      // 9. 재생 상태 모니터링
      player.playerStateStream.listen((state) {
        debugPrint('AlarmReceiver: 플레이어 상태 - ${state.processingState}, 재생중: ${state.playing}');

        // 만약 재생이 멈추면 다시 시작
        if (state.processingState == ProcessingState.completed && _keepAlivePlayer != null) {
          debugPrint('AlarmReceiver: 재생 완료됨, 다시 시작');
          _keepAlivePlayer!.seek(Duration.zero);
          _keepAlivePlayer!.play();
        }
      });

    } catch (e) {
      debugPrint('AlarmReceiver: 소리 재생 오류 발생: $e');

      // 백업 재생 시도
      try {
        await _playBackupSound();
      } catch (backupError) {
        debugPrint('AlarmReceiver: 백업 재생 실패: $backupError');
      }
    }
  }

  // 백업 재생 메서드
  static Future<void> _playBackupSound() async {
    debugPrint('AlarmReceiver: _playBackupSound 시작');

    try {
      debugPrint('AlarmReceiver: 백업 AudioPlayer 생성');
      final backupPlayer = AudioPlayer();

      debugPrint('AlarmReceiver: 백업 - 에셋 로드 시도');
      await backupPlayer.setAsset('assets/default_alarm.mp3');
      debugPrint('AlarmReceiver: 백업 - 에셋 로드 완료');

      debugPrint('AlarmReceiver: 백업 - 볼륨 설정 시도');
      await backupPlayer.setVolume(1.0);
      debugPrint('AlarmReceiver: 백업 - 볼륨 설정 완료');

      debugPrint('AlarmReceiver: 백업 - 루프 모드 설정 시도');
      await backupPlayer.setLoopMode(LoopMode.one);
      debugPrint('AlarmReceiver: 백업 - 루프 모드 설정 완료');

      debugPrint('AlarmReceiver: 백업 - 재생 시작 시도');
      await backupPlayer.play();
      debugPrint('AlarmReceiver: 백업 - 재생 시작 완료');

      _keepAlivePlayer = backupPlayer;
      debugPrint('AlarmReceiver: 백업 - 플레이어 참조 저장 완료');
    } catch (e) {
      debugPrint('AlarmReceiver: 백업 소리 재생 오류: $e');
    }
  }

  // 알람음 중지 기능 (외부에서 호출 가능)
  static Future<void> stopAlarmSound() async {
    try {
      if (_keepAlivePlayer != null) {
        debugPrint('AlarmReceiver: 알람음 중지 시도');
        await _keepAlivePlayer!.stop();
        await _keepAlivePlayer!.dispose();
        _keepAlivePlayer = null;
        debugPrint('AlarmReceiver: 알람음 중지 완료');
      } else {
        debugPrint('AlarmReceiver: 중지할 플레이어가 없음');
      }
    } catch (e) {
      debugPrint('AlarmReceiver: 알람음 중지 오류: $e');
    }
  }

  // 알람이 재생 중인지 확인
  static bool get isPlaying {
    return _keepAlivePlayer != null && (_keepAlivePlayer!.playing);
  }
}