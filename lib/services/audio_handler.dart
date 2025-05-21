// lib/services/audio_handler.dart - 파일 신규 생성
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/material.dart';

// 백그라운드 오디오 핸들러
class MyAudioHandler extends BaseAudioHandler {
  // 오디오 플레이어 인스턴스
  final AudioPlayer _player = AudioPlayer();
  
  // 현재 재생 중인 미디어 아이템
  MediaItem? _currentMediaItem;
  
  // 생성자에서 이벤트 핸들러 초기화
  MyAudioHandler() {
    // 플레이어 상태 이벤트 처리
    _player.playerStateStream.listen(_handlePlayerStateChanges);
    
    // 위치 변경 이벤트 처리
    _player.positionStream.listen((position) {
      playbackState.add(playbackState.value.copyWith(
        updatePosition: position,
        bufferedPosition: _player.bufferedPosition,
      ));
    });
  }
  
  // 플레이어 상태 변화 처리
  void _handlePlayerStateChanges(PlayerState state) {
    final playing = state.playing;
    final processingState = {
      ProcessingState.idle: AudioProcessingState.idle,
      ProcessingState.loading: AudioProcessingState.loading,
      ProcessingState.buffering: AudioProcessingState.buffering,
      ProcessingState.ready: AudioProcessingState.ready,
      ProcessingState.completed: AudioProcessingState.completed,
    }[state.processingState]!;
    
    // 현재 상태 업데이트 (잠금화면 및 백그라운드 알림에 표시됨)
    playbackState.add(playbackState.value.copyWith(
      playing: playing,
      processingState: processingState,
      controls: [
        MediaControl.rewind,              // 10초 뒤로
        MediaControl.skipToPrevious,      // 이전 트랙 (옵션)
        if (playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,                // 중지
        MediaControl.skipToNext,          // 다음 트랙 (옵션)
        MediaControl.fastForward,         // 10초 앞으로
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 2, 5], // 알림에 표시할 축약 컨트롤
    ));
  }
  
  // 미디어 파일 재생
  Future<void> playMediaFile(String filePath, String title, String? artist) async {
    try {
      // 현재 재생 중인 항목 정지
      await _player.stop();
      
      // 새 미디어 아이템 생성
      _currentMediaItem = MediaItem(
        id: filePath,
        title: title,
        artist: artist ?? 'Unknown',
        duration: await _getDuration(filePath),
      );
      
      // 미디어 아이템 정보 업데이트 (알림에 표시됨)
      mediaItem.add(_currentMediaItem);
      
      // 파일 경로 설정 및 재생
      await _player.setFilePath(filePath);
      await _player.play();
    } catch (e) {
      print('Media playback error: $e');
      throw Exception('미디어 재생 오류: $e');
    }
  }
  
  // 파일 Duration 가져오기
  Future<Duration?> _getDuration(String filePath) async {
    try {
      final duration = await _player.setFilePath(filePath, preload: true);
      return duration;
    } catch (e) {
      print('Error getting duration: $e');
      return null;
    }
  }
  
  // 아래는 백그라운드 및 잠금화면 컨트롤에서 호출되는 메서드들
  
  // 재생
  @override
  Future<void> play() async {
    await _player.play();
  }
  
  // 일시정지
  @override
  Future<void> pause() async {
    await _player.pause();
  }
  
  // 정지
  @override
  Future<void> stop() async {
    await _player.stop();
  }
  
  // 탐색
  @override
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }
  
  // 10초 뒤로
  @override
  Future<void> rewind() async {
    final position = _player.position;
    await _player.seek(position - const Duration(seconds: 10));
  }
  
  // 10초 앞으로
  @override
  Future<void> fastForward() async {
    final position = _player.position;
    await _player.seek(position + const Duration(seconds: 10));
  }
  
  // 리소스 해제
  @override
  Future<void> onTaskRemoved() async {
    await stop();
    await _player.dispose();
    super.onTaskRemoved();
  }
}

// 백그라운드 오디오 서비스 초기화
Future<AudioHandler> initAudioService() async {
  return await AudioService.init(
    builder: () => MyAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.example.lingedge1.audio',
      androidNotificationChannelName: 'MP3 Player',
      // 알림 아이콘은 옵션 (기본 앱 아이콘 사용 가능)
      // androidNotificationIcon: 'drawable/ic_notification',
      androidShowNotificationBadge: true,
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
      notificationColor: Color(0xFF3498DB),
      fastForwardInterval: Duration(seconds: 10),
      rewindInterval: Duration(seconds: 10),
    ),
  );
}