// lib/services/audio_background_handler.dart

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/material.dart';

Future<AudioHandler> initAudioService() async {
  return await AudioService.init(
    builder: () => AudioPlayerHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.example.lingedge1.audio',
      androidNotificationChannelName: 'MP3 Player',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );
}

class AudioPlayerHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final _player = AudioPlayer();
  
  AudioPlayerHandler() {
    _player.playbackEventStream.listen(_broadcastState);
    
    // 기본 컨트롤 처리
    playbackState.add(PlaybackState(
      controls: [
        MediaControl.rewind,
        MediaControl.play,
        MediaControl.stop,
        MediaControl.fastForward,
      ],
      systemActions: const {
        MediaAction.seek,
      },
      processingState: AudioProcessingState.idle,
      playing: false,
    ));
  }
  
  // 플레이어 상태 변경 시 브로드캐스트
  void _broadcastState(PlaybackEvent event) {
    final playing = _player.playing;
    playbackState.add(PlaybackState(
      controls: [
        MediaControl.rewind,
        if (playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
        MediaControl.fastForward,
      ],
      systemActions: const {
        MediaAction.seek,
      },
      androidCompactActionIndices: const [0, 1, 3],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
    ));
  }
  
  @override
  Future<void> play() async {
    await _player.play();
  }
  
  @override
  Future<void> pause() async {
    await _player.pause();
  }
  
  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }
  
  @override
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }
  
  @override
  Future<void> playMediaItem(MediaItem mediaItem) async {
    try {
      await _player.stop();
      await _player.setUrl(mediaItem.id);
      
      // MediaItem에 duration 직접 할당이 아닌, 새로운 MediaItem 생성
      // 플레이어가 로드된 후 duration을 가져올 수 있음
      await _player.load();
      final duration = _player.duration;
      
      if (duration != null) {
        // duration을 포함한 새 MediaItem 생성
        final updatedMediaItem = MediaItem(
          id: mediaItem.id,
          title: mediaItem.title,
          artist: mediaItem.artist,
          duration: duration,
          artUri: mediaItem.artUri,
        );
        
        // 새 MediaItem을 스트림에 추가
        this.mediaItem.add(updatedMediaItem);
      } else {
        // duration을 가져올 수 없을 경우 원본 미디어 아이템 사용
        this.mediaItem.add(mediaItem);
      }
      
      await _player.play();
    } catch (e) {
      debugPrint('Error playing media item: $e');
    }
  }
  
  // 파일 경로로 직접 재생
  Future<void> playFile(String filePath, String title, String? artist) async {
    try {
      final mediaItem = MediaItem(
        id: filePath,
        title: title,
        artist: artist ?? '알 수 없음',
        artUri: Uri.parse('asset:///assets/default_cover.png'),
      );
      
      await playMediaItem(mediaItem);
    } catch (e) {
      debugPrint('Error playing file: $e');
      rethrow;
    }
  }
  
  // URL로 재생
  Future<void> playUrl(String url, String title, String? artist) async {
    try {
      final mediaItem = MediaItem(
        id: url,
        title: title,
        artist: artist ?? '알 수 없음',
        artUri: Uri.parse('asset:///assets/default_cover.png'),
      );
      
      await playMediaItem(mediaItem);
    } catch (e) {
      debugPrint('Error playing URL: $e');
      rethrow;
    }
  }
  
  @override
  Future<void> onTaskRemoved() async {
    await stop();
  }
  
  // 플레이어 상태 확인
  Future<bool> isPlaying() async {
    return _player.playing;
  }
  
  // 현재 재생 시간 가져오기
  Stream<Duration> get positionStream => _player.positionStream;
  
  // 총 재생 시간 가져오기
  Duration? get duration => _player.duration;
}