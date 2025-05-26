// lib/services/audio_player_service.dart
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';

class AudioPlayerService {
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  
  factory AudioPlayerService() => _instance;
  
  AudioPlayerService._internal() {
    _initPlayer();
  }
  
  AudioPlayer? _audioPlayer;
  BehaviorSubject<PlaybackState>? _playbackState;
  BehaviorSubject<MediaItem?>? _mediaItem;
  bool _isInitialized = false;
  
  AudioPlayer get audioPlayer {
    if (_audioPlayer == null) {
      _initPlayer();
    }
    return _audioPlayer!;
  }
  
  Stream<PlaybackState> get playbackStateStream => 
      _playbackState?.stream ?? Stream.value(PlaybackState());
  
  Stream<MediaItem?> get mediaItemStream => 
      _mediaItem?.stream ?? Stream.value(null);
  
  void _initPlayer() {
    _audioPlayer = AudioPlayer();
    _playbackState = BehaviorSubject<PlaybackState>();
    _mediaItem = BehaviorSubject<MediaItem?>();
  }
  
  // 초기화 - 비동기 처리 개선
  Future<void> init() async {
    if (_isInitialized) return;
    
    try {
      // 이미 초기화된 경우 리소스 해제
      if (_audioPlayer == null) {
        _initPlayer();
      }
      
      // 오디오 플레이어 이벤트 구독
      _audioPlayer!.playbackEventStream.listen((event) {
        try {
          if (_playbackState == null || _playbackState!.isClosed) return;
          
          final playing = _audioPlayer!.playing;
          final processingState = {
            ProcessingState.idle: AudioProcessingState.idle,
            ProcessingState.loading: AudioProcessingState.loading,
            ProcessingState.buffering: AudioProcessingState.buffering,
            ProcessingState.ready: AudioProcessingState.ready,
            ProcessingState.completed: AudioProcessingState.completed,
          }[_audioPlayer!.processingState];
          
          _playbackState!.add(PlaybackState(
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
            updatePosition: _audioPlayer!.position,
            bufferedPosition: _audioPlayer!.bufferedPosition,
            speed: _audioPlayer!.speed,
          ));
        } catch (e) {
          debugPrint('플레이백 상태 업데이트 오류: $e');
        }
      });
      
      _audioPlayer!.currentIndexStream.listen((index) {
        if (index != null) {
          // 현재 재생 중인 미디어 아이템 업데이트
        }
      }, onError: (e) {
        debugPrint('현재 인덱스 스트림 오류: $e');
      });
      
      _isInitialized = true;
    } catch (e) {
      debugPrint('오디오 플레이어 초기화 오류: $e');
      throw Exception('오디오 플레이어 초기화 실패: $e');
    }
  }
  
  // MP3 파일 재생
  Future<void> playMp3(String url, String title, String? artist, {Map<String, String>? headers}) async {
    try {
      // 초기화 확인
      if (!_isInitialized || _audioPlayer == null) {
        await init();
      }
      
      // 현재 재생 중인 항목이 있으면 중지
      await _audioPlayer!.stop();
      
      // 새 미디어 항목 설정
      final mediaItem = MediaItem(
        id: url,
        title: title,
        artist: artist ?? '알 수 없음',
        artUri: Uri.parse('asset:///assets/default_cover.png'),
      );
      
      if (_mediaItem != null && !_mediaItem!.isClosed) {
        _mediaItem!.add(mediaItem);
      }
      
      // 새 오디오 소스 설정
      await _audioPlayer!.setUrl(url, headers: headers);
      
      // 재생 시작
      await _audioPlayer!.play();
    } catch (e) {
      debugPrint('오디오 재생 오류: $e');
      throw Exception('오디오 재생 실패: $e');
    }
  }
  
  // 재생/일시정지 토글
  Future<void> playOrPause() async {
    try {
      if (_audioPlayer == null) {
        await init();
      }
      
      if (_audioPlayer!.playing) {
        await _audioPlayer!.pause();
      } else {
        await _audioPlayer!.play();
      }
    } catch (e) {
      debugPrint('재생/일시정지 오류: $e');
      throw Exception('재생 제어 실패: $e');
    }
  }
  
  // 정지
  Future<void> stop() async {
    try {
      if (_audioPlayer != null) {
        await _audioPlayer!.stop();
      }
      
      if (_mediaItem != null && !_mediaItem!.isClosed) {
        _mediaItem!.add(null);
      }
    } catch (e) {
      debugPrint('재생 정지 오류: $e');
      throw Exception('재생 정지 실패: $e');
    }
  }
  
  // 리소스 해제
  Future<void> dispose() async {
    try {
      await stop();
      
      if (_audioPlayer != null) {
        await _audioPlayer!.dispose();
        _audioPlayer = null;
      }
      
      if (_playbackState != null && !_playbackState!.isClosed) {
        await _playbackState!.close();
        _playbackState = null;
      }
      
      if (_mediaItem != null && !_mediaItem!.isClosed) {
        await _mediaItem!.close();
        _mediaItem = null;
      }
      
      _isInitialized = false;
    } catch (e) {
      debugPrint('리소스 해제 오류: $e');
    }
  }
}