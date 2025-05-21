// lib/screens/mp3_player_screen.dart

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:audio_service/audio_service.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../config/theme.dart';
import '../models/user_file.dart';
import '../providers/file_provider.dart';
import '../services/audio_background_handler.dart';
import '../main.dart'; // audioHandler 전역 변수에 접근하기 위해 추가

class MP3PlayerScreen extends StatefulWidget {
  const MP3PlayerScreen({Key? key}) : super(key: key);

  @override
  State<MP3PlayerScreen> createState() => _MP3PlayerScreenState();
}

class _MP3PlayerScreenState extends State<MP3PlayerScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  UserFile? _currentFile;
  bool _isInitializing = true;
  String? _errorMessage;
  bool _isDownloading = false;
  final Map<int, String> _downloadedFilePaths = {};
  bool _showMiniPlayer = false;
  
  // 전역 변수 audioHandler 사용 (AudioService.audioHandler 대신)
  late AudioHandler _audioHandler;
  
  @override
  void initState() {
    super.initState();
    _audioHandler = audioHandler; // main.dart에서 export된 전역 변수 사용
    _initializePlayer();
  }
  
  Future<void> _initializePlayer() async {
    try {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
        
        // 비동기로 파일 목록 가져오기
        Future.microtask(() {
          if (mounted) {
            Provider.of<FileProvider>(context, listen: false).fetchAudioFiles();
          }
        });
        
        // 현재 재생 중인 미디어 아이템 확인
        _audioHandler.mediaItem.listen((mediaItem) {
          if (mediaItem != null && mounted) {
            setState(() {
              _showMiniPlayer = true;
            });
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _errorMessage = '플레이어 초기화 오류: $e';
          debugPrint(_errorMessage);
        });
      }
    }
  }
  
  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
  
  // MP3 파일 다운로드 후 재생 메서드
  Future<void> _playMp3(UserFile file) async {
    // 이미 다운로드 중이면 중복 실행 방지
    if (_isDownloading) {
      return;
    }
    
    try {
      setState(() {
        _currentFile = file;
        _errorMessage = null;
        _isDownloading = true;
        _showMiniPlayer = true;
      });
      
      // 이미 다운로드된 파일이 있는지 확인
      if (_downloadedFilePaths.containsKey(file.id)) {
        final cachedFilePath = _downloadedFilePaths[file.id];
        final cachedFile = File(cachedFilePath!);
        
        // 파일이 실제로 존재하는지 확인
        if (await cachedFile.exists()) {
          debugPrint('캐시된 파일 사용: $cachedFilePath');
          
          // 오디오 서비스로 재생
          await (_audioHandler as AudioPlayerHandler).playFile(
            cachedFilePath, 
            file.fileName, 
            'LinguaEdge MP3'
          );
          
          setState(() {
            _isDownloading = false;
          });
          return;
        }
      }
      
      // 로딩 상태 표시
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${file.fileName} 다운로드 중...')),
      );
      
      // 토큰 가져오기
      final tokenService = await SharedPreferences.getInstance();
      final token = tokenService.getString('auth_token');
      
      if (token == null) {
        throw Exception('인증 토큰이 없습니다. 다시 로그인해주세요.');
      }
      
      // 다운로드 URL 생성
      final url = 'https://port-0-java-springboot-lan-m8dt2pjh3adde56e.sel4.cloudtype.app/api/files/download/${file.id}?token=$token';
      
      debugPrint('다운로드 URL: $url');
      
      // HTTP 요청으로 파일 다운로드
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      
      debugPrint('HTTP 응답 코드: ${response.statusCode}');
      
      if (response.statusCode != 200) {
        throw Exception('파일 다운로드 실패. 상태 코드: ${response.statusCode}');
      }
      
      // 응답 크기 확인
      debugPrint('다운로드 파일 크기: ${response.bodyBytes.length} 바이트');
      
      if (response.bodyBytes.isEmpty) {
        throw Exception('다운로드된 파일이 비어있습니다.');
      }
      
      // 임시 디렉토리에 파일 저장
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/${file.fileName}');
      await tempFile.writeAsBytes(response.bodyBytes);
      
      final filePath = tempFile.path;
      debugPrint('임시 파일 저장 경로: $filePath');
      
      // 파일 경로 캐시
      _downloadedFilePaths[file.id] = filePath;
      
      // 다운로드 완료 알림
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${file.fileName} 다운로드 완료, 재생 시작')),
      );
      
      // 오디오 서비스로 재생
      await (_audioHandler as AudioPlayerHandler).playFile(
        filePath, 
        file.fileName, 
        'LinguaEdge MP3'
      );
      
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '파일 재생 오류: $e';
          debugPrint(_errorMessage);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('파일 재생 중 오류가 발생했습니다: $e')),
        );
      }
    } finally {
      // 작업 완료 후 다운로드 상태 해제
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 이하 코드는 동일...
    if (_isInitializing) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(title: const Text('MP3 플레이어')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('플레이어를 초기화하는 중...'),
            ],
          ),
        ),
      );
    }
    
    // 나머지 build 메서드 코드...
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('MP3 플레이어'),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // 파일 목록
              Expanded(
                child: Consumer<FileProvider>(
                  builder: (context, fileProvider, child) {
                    if (fileProvider.isLoading) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                    
                    // 오류 발생 시 표시
                    if (fileProvider.error != null) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red, size: 48),
                            const SizedBox(height: 16),
                            Text('파일 목록 오류: ${fileProvider.error}', textAlign: TextAlign.center),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => fileProvider.fetchAudioFiles(),
                              child: const Text('다시 시도'),
                            ),
                          ],
                        ),
                      );
                    }
                    
                    final audioFiles = fileProvider.audioFiles;
                    
                    if (audioFiles.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.audio_file,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'MP3 파일이 없습니다',
                              style: AppTheme.titleMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              '파일 업로드 화면에서 MP3 파일을 업로드해주세요.',
                              style: AppTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.upload_file),
                              label: const Text('파일 업로드'),
                              onPressed: () {
                                Navigator.pushNamed(context, '/files/upload');
                              },
                            ),
                          ],
                        ),
                      );
                    }
                    
                    // 미니 플레이어 공간 확보를 위한 padding 추가
                    return ListView.builder(
                      itemCount: audioFiles.length,
                      padding: EdgeInsets.only(bottom: _showMiniPlayer ? 80 : 0),
                      itemBuilder: (context, index) {
                        final file = audioFiles[index];
                        
                        // 현재 재생 중인 파일 확인 (스트림 사용)
                        return StreamBuilder<MediaItem?>(
                          stream: _audioHandler.mediaItem,
                          builder: (context, snapshot) {
                            final currentMediaItem = snapshot.data;
                            final isPlaying = currentMediaItem != null && 
                                file.fileName == currentMediaItem.title;
                            
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: ListTile(
                                leading: Icon(
                                  Icons.audio_file,
                                  color: isPlaying ? AppTheme.primaryColor : Colors.grey,
                                ),
                                title: Text(
                                  file.fileName,
                                  style: TextStyle(
                                    fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
                                    color: isPlaying ? AppTheme.primaryColor : null,
                                  ),
                                ),
                                subtitle: Text(
                                  '생성일: ${_formatDate(file.createdAt)}',
                                  style: AppTheme.bodySmall,
                                ),
                                trailing: isPlaying 
                                    ? const Icon(Icons.equalizer, color: AppTheme.primaryColor)
                                    : null,
                                onTap: () {
                                  // 이미 재생 중이거나 다운로드 중이면 중복 실행 방지
                                  if (isPlaying || _isDownloading) {
                                    return;
                                  }
                                  _playMp3(file);
                                },
                              ),
                            );
                          }
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          
          // 미니 플레이어
          if (_showMiniPlayer)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildMiniPlayer(),
            ),
        ],
      ),
    );
  }
  
  // 미니 플레이어 위젯
  Widget _buildMiniPlayer() {
    return StreamBuilder<MediaItem?>(
      stream: _audioHandler.mediaItem,
      builder: (context, mediaItemSnapshot) {
        final mediaItem = mediaItemSnapshot.data;
        
        // 재생 중인 미디어가 없으면 표시하지 않음
        if (mediaItem == null) {
          return const SizedBox.shrink();
        }
        
        return Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.8),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Row(
            children: [
              // 앨범 아트 (없으면 아이콘)
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(Icons.music_note, color: Colors.white),
              ),
              const SizedBox(width: 12),
              
              // 노래 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      mediaItem.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    // 재생 진행 표시줄
                    StreamBuilder<Duration>(
                      stream: _audioPlayer.positionStream,
                      builder: (context, snapshot) {
                        final position = snapshot.data ?? Duration.zero;
                        final duration = mediaItem.duration ?? Duration.zero;
                        
                        double progressValue = 0.0;
                        if (duration.inMilliseconds > 0) {
                          progressValue = position.inMilliseconds / duration.inMilliseconds;
                          if (progressValue < 0) progressValue = 0;
                          if (progressValue > 1) progressValue = 1;
                        }
                        
                        return Row(
                          children: [
                            Text(
                              _formatDuration(position),
                              style: TextStyle(color: Colors.grey[400], fontSize: 12),
                            ),
                            Expanded(
                              child: SliderTheme(
                                data: SliderThemeData(
                                  trackHeight: 2,
                                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
                                ),
                                child: Slider(
                                  value: progressValue,
                                  onChanged: (value) {
                                    if (duration.inMilliseconds > 0) {
                                      final newPosition = Duration(
                                        milliseconds: (value * duration.inMilliseconds).round()
                                      );
                                      _audioHandler.seek(newPosition);
                                    }
                                  },
                                  activeColor: Colors.white,
                                  inactiveColor: Colors.grey[600],
                                ),
                              ),
                            ),
                            Text(
                              _formatDuration(duration),
                              style: TextStyle(color: Colors.grey[400], fontSize: 12),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              
              // 컨트롤 버튼
              IconButton(
                icon: const Icon(Icons.skip_previous, color: Colors.white),
                onPressed: () {
                  try {
                    // 처음으로 되감기
                    _audioHandler.seek(Duration.zero);
                  } catch (e) {
                    debugPrint('되감기 오류: $e');
                  }
                },
                iconSize: 28,
              ),
              
              StreamBuilder<PlaybackState>(
                stream: _audioHandler.playbackState,
                builder: (context, snapshot) {
                  final playbackState = snapshot.data;
                  final playing = playbackState?.playing ?? false;
                  return IconButton(
                    icon: Icon(
                      playing ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      try {
                        if (playing) {
                          _audioHandler.pause();
                        } else {
                          _audioHandler.play();
                        }
                      } catch (e) {
                        debugPrint('재생/일시정지 오류: $e');
                      }
                    },
                    iconSize: 32,
                  );
                },
              ),
              
              IconButton(
                icon: const Icon(Icons.skip_next, color: Colors.white),
                onPressed: () {
                  try {
                    // 다음 곡 기능 (필요하면 구현)
                    // 현재는 기능이 없음
                  } catch (e) {
                    debugPrint('다음 곡 오류: $e');
                  }
                },
                iconSize: 28,
              ),
            ],
          ),
        );
      },
    );
  }
  
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
  
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}