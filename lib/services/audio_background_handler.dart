// lib/services/audio_background_handler.dart

import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/material.dart';

// 백그라운드 오디오 서비스 초기화
Future<AudioHandler> initAudioService() async {
  return await AudioService.init(
    builder: () => AudioPlayerHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.example.lingedge1.audio',
      androidNotificationChannelName: 'MP3 Player',
      androidNotificationIcon: 'drawable/ic_notification', // 알림 아이콘 설정
      androidShowNotificationBadge: true,
      // 일시정지 시 알림을 계속 표시하고 싶으면 두 설정을 모두 true로 설정
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true, // 오류 수정: 둘 다 true로 설정
      notificationColor: Color(0xFF3498DB), // 알림 색상
      artDownscaleWidth: 300, // 앨범 아트 크기
      artDownscaleHeight: 300,
    ),
  );
}

class AudioPlayerHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final _player = AudioPlayer();
  
  AudioPlayerHandler() {
    // 플레이어 상태 이벤트 처리
    _player.playbackEventStream.listen(_broadcastState);
    
    // 기본 컨트롤 설정 - 백그라운드 알림에 표시될 컨트롤
    playbackState.add(PlaybackState(
      controls: [
        MediaControl.skipToPrevious, // 이전 버튼
        MediaControl.play,           // 재생 버튼 
        MediaControl.skipToNext,     // 다음 버튼
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      processingState: AudioProcessingState.idle,
      playing: false,
      androidCompactActionIndices: const [0, 1, 2], // 축소된 알림에 표시할 컨트롤 인덱스
    ));
  }
  
  // 플레이어 상태 변경 시 브로드캐스트
  void _broadcastState(PlaybackEvent event) {
    final playing = _player.playing;
    final processingState = {
      ProcessingState.idle: AudioProcessingState.idle,
      ProcessingState.loading: AudioProcessingState.loading,
      ProcessingState.buffering: AudioProcessingState.buffering,
      ProcessingState.ready: AudioProcessingState.ready,
      ProcessingState.completed: AudioProcessingState.completed,
    }[_player.processingState]!;
    
    // 현재 상태 업데이트 (잠금화면 및 백그라운드 알림에 표시됨)
    playbackState.add(PlaybackState(
      controls: [
        MediaControl.skipToPrevious,              // 이전
        if (playing) MediaControl.pause else MediaControl.play, // 재생/일시정지
        MediaControl.skipToNext,                  // 다음
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 2], // 알림에 표시할 컨트롤 (3개만 가능)
      processingState: processingState,
      playing: playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
    ));
  }
  
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
    await super.stop();
  }
  
  // 특정 위치로 이동
  @override
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }
  
  // 뒤로 10초 이동 (잠금화면 컨트롤로 사용)
  @override
  Future<void> skipToPrevious() async {
    final position = _player.position;
    final newPosition = position - const Duration(seconds: 10);
    if (newPosition.isNegative) {
      await _player.seek(Duration.zero);
    } else {
      await _player.seek(newPosition);
    }
  }
  
  // 앞으로 10초 이동 (잠금화면 컨트롤로 사용)
  @override
  Future<void> skipToNext() async {
    final position = _player.position;
    final duration = _player.duration ?? Duration.zero;
    final newPosition = position + const Duration(seconds: 10);
    if (newPosition > duration) {
      await _player.seek(duration);
    } else {
      await _player.seek(newPosition);
    }
  }
  
  // 미디어 재생
  @override
  Future<void> playMediaItem(MediaItem mediaItem) async {
    try {
      await _player.stop();
      
      // URL로 오디오 설정
      await _player.setUrl(mediaItem.id);
      
      // 오디오 로드 (재생하지 않고 미디어 정보만 가져옴)
      await _player.load();
      
      // 오디오 파일 정보 업데이트 (재생 시간 등)
      final duration = _player.duration;
      MediaItem updatedItem;
      
      if (duration != null) {
        // 재생 시간 정보 추가하여 갱신
        updatedItem = mediaItem.copyWith(
          duration: duration,
        );
      } else {
        updatedItem = mediaItem;
      }
      
      // 미디어 정보 업데이트 (알림/잠금화면에 표시)
      this.mediaItem.add(updatedItem);
      
      // 재생 시작
      await _player.play();
    } catch (e) {
      debugPrint('미디어 재생 오류: $e');
    }
  }
  
  // 파일 재생 (사용자 정의 메서드)
  Future<void> playFile(String filePath, String title, String? artist) async {
    try {
      // 미디어 아이템 생성
      final mediaItem = MediaItem(
        id: filePath,
        title: title,
        artist: artist ?? 'LinguaEdge MP3', // 비어있으면 기본값 사용
        displayTitle: title,
        displaySubtitle: artist ?? 'LinguaEdge MP3',
      );
      
      // 공식 MediaItem 재생 메서드 사용
      await playMediaItem(mediaItem);
    } catch (e) {
      debugPrint('파일 재생 오류: $e');
      rethrow;
    }
  }
  
  // URL 재생 (사용자 정의 메서드)
  Future<void> playUrl(String url, String title, String? artist) async {
    try {
      // 미디어 아이템 생성
      final mediaItem = MediaItem(
        id: url,
        title: title,
        artist: artist ?? 'LinguaEdge MP3',
        displayTitle: title,
        displaySubtitle: artist ?? 'LinguaEdge MP3',
      );
      
      // 공식 MediaItem 재생 메서드 사용
      await playMediaItem(mediaItem);
    } catch (e) {
      debugPrint('URL 재생 오류: $e');
      rethrow;
    }
  }
  
  // 커스텀 액션 처리
  @override
  Future<dynamic> customAction(String name, [Map<String, dynamic>? extras]) async {
    switch(name) {
      case 'stopCurrent':
        await _player.stop();
        return true;
      case 'dispose':
        await _player.dispose();
        return true;
      default:
        return super.customAction(name, extras);
    }
  }
  
  // 앱이 종료될 때 호출
  @override
  Future<void> onTaskRemoved() async {
    await stop();
  }
  
  // 내부 플레이어 인스턴스 접근용 getter
  AudioPlayer get player => _player;
  
  // 시간 형식화 함수
  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}