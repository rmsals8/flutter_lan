// lib/services/audio_player_service.dart
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';

class AudioPlayerService {
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  
  factory AudioPlayerService() => _instance;
  
  AudioPlayerService._internal();
  
  final AudioPlayer _audioPlayer = AudioPlayer();
  final _playbackState = BehaviorSubject<PlaybackState>();
  final _mediaItem = BehaviorSubject<MediaItem?>();
  
  Stream<PlaybackState> get playbackStateStream => _playbackState.stream;
  Stream<MediaItem?> get mediaItemStream => _mediaItem.stream;
  
  AudioPlayer get audioPlayer => _audioPlayer;
  
  // 초기화
  Future<void> init() async {
    // 오디오 플레이어 이벤트 구독
    _audioPlayer.playbackEventStream.listen((event) {
      final playing = _audioPlayer.playing;
      final processingState = {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_audioPlayer.processingState];
      
      _playbackState.add(PlaybackState(
        controls: [
          MediaControl.rewind,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.stop,
          MediaControl.fastForward,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 3],
        processingState: processingState ?? AudioProcessingState.idle,
        playing: playing,
        updatePosition: _audioPlayer.position,
        bufferedPosition: _audioPlayer.bufferedPosition,
        speed: _audioPlayer.speed,
      ));
    });
    
    _audioPlayer.currentIndexStream.listen((index) {
      if (index != null) {
        // 현재 재생 중인 미디어 아이템 업데이트
      }
    });
  }
  
  // MP3 파일 재생
  Future<void> playMp3(String url, String title, String? artist) async {
    try {
      // 현재 재생 중인 항목이 있으면 중지
      await _audioPlayer.stop();
      
      // 새 미디어 항목 설정
      final mediaItem = MediaItem(
        id: url,
        title: title,
        artist: artist ?? '알 수 없음',
        artUri: Uri.parse('asset:///assets/default_cover.png'),
      );
      
      _mediaItem.add(mediaItem);
      
      // 새 오디오 소스 설정 및 재생
      await _audioPlayer.setUrl(url);
      await _audioPlayer.play();
    } catch (e) {
      debugPrint('오디오 재생 오류: $e');
    }
  }
  
  // 재생/일시정지 토글
  Future<void> playOrPause() async {
    if (_audioPlayer.playing) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play();
    }
  }
  
  // 정지
  Future<void> stop() async {
    await _audioPlayer.stop();
    _mediaItem.add(null);
  }
  
  // 리소스 해제
  Future<void> dispose() async {
    await _audioPlayer.dispose();
    await _playbackState.close();
    await _mediaItem.close();
  }
}