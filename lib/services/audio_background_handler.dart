import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

Future<AudioHandler> initAudioService() async {
  return await AudioService.init(
    builder: () => MyAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.example.lingedge1.audio',
      androidNotificationChannelName: 'MP3 Player',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );
}

class MyAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final _player = AudioPlayer();
  
  MyAudioHandler() {
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
    await _player.stop();
    await _player.setUrl(mediaItem.id);
    
    // MediaItem의 duration 직접 할당이 아닌, 새로운 MediaItem 생성
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
  }
  
  @override
  Future<void> onTaskRemoved() async {
    await stop();
  }
}