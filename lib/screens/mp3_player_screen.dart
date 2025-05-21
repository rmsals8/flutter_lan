// lib/screens/mp3_player_screen.dart
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/user_file.dart';
import '../providers/file_provider.dart';
import '../services/audio_player_service.dart';
import '../utils/browser_downloader.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audio_session/audio_session.dart';

class MP3PlayerScreen extends StatefulWidget {
  const MP3PlayerScreen({Key? key}) : super(key: key);

  @override
  State<MP3PlayerScreen> createState() => _MP3PlayerScreenState();
}

class _MP3PlayerScreenState extends State<MP3PlayerScreen> {
  final AudioPlayerService _audioPlayerService = AudioPlayerService();
  UserFile? _currentFile;
  bool _isInitializing = true;
  String? _errorMessage;
  bool _isDownloading = false; // 다운로드 중 상태 추가
  
  // 다운로드된 파일 경로를 캐시
  final Map<int, String> _downloadedFilePaths = {};
  
  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }
  
  Future<void> _initializePlayer() async {
    try {
      await _audioPlayerService.init();
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
    // 리소스 정리
    _audioPlayerService.dispose();
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
        _isDownloading = true; // 다운로드 시작
      });
      
      // 이미 다운로드된 파일이 있는지 확인
      if (_downloadedFilePaths.containsKey(file.id)) {
        final cachedFilePath = _downloadedFilePaths[file.id];
        final cachedFile = File(cachedFilePath!);
        
        // 파일이 실제로 존재하는지 확인
        if (await cachedFile.exists()) {
          debugPrint('캐시된 파일 사용: $cachedFilePath');
          
          // 로컬 파일에서 바로 재생
          await _audioPlayerService.audioPlayer.setFilePath(cachedFilePath);
          await _audioPlayerService.audioPlayer.play();
          
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
      
      // 로컬 파일에서 재생
      await _audioPlayerService.audioPlayer.setFilePath(filePath);
      await _audioPlayerService.audioPlayer.play();
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
  
  // 토큰을 포함한 URL 생성 메서드 수정
  Future<Uri> _getTokenUrl(String baseUrl) async {
    try {
      // 스토리지에서 토큰 가져오기
      final tokenService = await SharedPreferences.getInstance();
      final token = tokenService.getString('auth_token');
      
      if (token == null) {
        throw Exception('인증 토큰이 없습니다. 다시 로그인해주세요.');
      }
      
      // URL에 토큰 파라미터 추가
      final uri = Uri.parse(baseUrl);
      final newUri = uri.replace(
        queryParameters: {
          ...uri.queryParameters,
          'token': token,
        },
      );
      
      debugPrint('생성된 URL: $newUri');
      return newUri;
    } catch (e) {
      debugPrint('토큰 URL 생성 오류: $e');
      throw Exception('토큰 URL 생성 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // 초기화 중이거나 오류 발생 시 처리
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
    
    // 오류 발생 시 표시
    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(title: const Text('MP3 플레이어')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isInitializing = true;
                    _errorMessage = null;
                  });
                  _initializePlayer();
                },
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      );
    }

    // 정상 화면 표시
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('MP3 플레이어'),
      ),
      body: Column(
        children: [
          // 현재 재생 중인 파일 정보
          _buildNowPlaying(),
          
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
                  return _buildEmptyState();
                }
                
                return ListView.builder(
                  itemCount: audioFiles.length,
                  itemBuilder: (context, index) {
                    final file = audioFiles[index];
                    final isPlaying = _currentFile?.id == file.id;
                    
                    return _buildAudioFileItem(file, isPlaying);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  // 현재 재생 중인 파일 UI - 에러 처리 추가
  Widget _buildNowPlaying() {
    return StreamBuilder<Duration>(
      stream: _audioPlayerService.audioPlayer.positionStream,
      builder: (context, snapshot) {
        // 스트림 데이터 누락 시
        if (snapshot.hasError) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.red.withOpacity(0.1),
            child: Text('재생 정보 오류: ${snapshot.error}'),
          );
        }
        
        final position = snapshot.data ?? Duration.zero;
        final duration = _audioPlayerService.audioPlayer.duration ?? Duration.zero;
        double progressValue = 0.0;
        
        // 안전하게 진행 값 계산
        if (duration.inMilliseconds > 0) {
          progressValue = position.inMilliseconds / duration.inMilliseconds;
          // 값이 범위를 벗어나지 않도록 조정
          if (progressValue < 0) progressValue = 0;
          if (progressValue > 1) progressValue = 1;
        }
        
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // 재생 중인 파일 이름
              Text(
                _currentFile?.fileName ?? '재생 중인 파일 없음',
                style: AppTheme.titleMedium,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              
              // 진행 바
              LinearProgressIndicator(
                value: progressValue,
                backgroundColor: Colors.grey[300],
                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              ),
              const SizedBox(height: 8),
              
              // 시간 표시
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_formatDuration(position)),
                  Text(_formatDuration(duration)),
                ],
              ),
              const SizedBox(height: 8),
              
              // 컨트롤 버튼
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.replay_10),
                    onPressed: () {
                      try {
                        final newPosition = position - const Duration(seconds: 10);
                        _audioPlayerService.audioPlayer.seek(newPosition);
                      } catch (e) {
                        debugPrint('되감기 오류: $e');
                      }
                    },
                  ),
                  const SizedBox(width: 16),
                  StreamBuilder<bool>(
                    stream: _audioPlayerService.audioPlayer.playingStream,
                    builder: (context, snapshot) {
                      final isPlaying = snapshot.data ?? false;
                      return IconButton(
                        icon: Icon(
                          isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                          size: 48,
                        ),
                        color: AppTheme.primaryColor,
                        onPressed: () {
                          try {
                            _audioPlayerService.playOrPause();
                          } catch (e) {
                            debugPrint('재생/일시정지 오류: $e');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('재생 제어 오류: $e')),
                            );
                          }
                        },
                      );
                    },
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.forward_10),
                    onPressed: () {
                      try {
                        final newPosition = position + const Duration(seconds: 10);
                        _audioPlayerService.audioPlayer.seek(newPosition);
                      } catch (e) {
                        debugPrint('빨리감기 오류: $e');
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
  
  // 오디오 파일 항목 위젯 - 재생 버튼 제거
  Widget _buildAudioFileItem(UserFile file, bool isPlaying) {
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
        // 재생 버튼 제거, 아래쪽에 있던 재생 버튼 삭제
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
  
  // 빈 상태 위젯
  Widget _buildEmptyState() {
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
  
  // 시간 형식 변환 (00:00 형식)
  String _formatDuration(Duration duration) {
    try {
      String twoDigits(int n) => n.toString().padLeft(2, '0');
      final minutes = twoDigits(duration.inMinutes.remainder(60));
      final seconds = twoDigits(duration.inSeconds.remainder(60));
      return '$minutes:$seconds';
    } catch (e) {
      debugPrint('시간 형식 변환 오류: $e');
      return '00:00';
    }
  }
  
  // 날짜 형식 변환
  String _formatDate(DateTime date) {
    try {
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      debugPrint('날짜 형식 변환 오류: $e');
      return '날짜 정보 없음';
    }
  }
}