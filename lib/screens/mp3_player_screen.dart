// lib/screens/mp3_player_screen.dart
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/user_file.dart';
import '../providers/file_provider.dart';
import '../services/audio_player_service.dart';
import '../utils/browser_downloader.dart';

class MP3PlayerScreen extends StatefulWidget {
  const MP3PlayerScreen({Key? key}) : super(key: key);

  @override
  State<MP3PlayerScreen> createState() => _MP3PlayerScreenState();
}

class _MP3PlayerScreenState extends State<MP3PlayerScreen> {
  final AudioPlayerService _audioPlayerService = AudioPlayerService();
  UserFile? _currentFile;
  
  @override
  void initState() {
    super.initState();
    _audioPlayerService.init();
    
    // 오디오 파일 목록 가져오기
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FileProvider>(context, listen: false).fetchAudioFiles();
    });
  }
  
  @override
  void dispose() {
    super.dispose();
  }
  
  // MP3 파일 재생 함수
  Future<void> _playMp3(UserFile file) async {
    setState(() {
      _currentFile = file;
    });
    
    // 파일 URL 생성
    final url = 'https://port-0-java-springboot-lan-m8dt2pjh3adde56e.sel4.cloudtype.app/api/files/download/${file.id}';
    
    // 토큰이 필요한 URL일 경우 토큰 포함 URL 생성
    final tokenUrl = await _getTokenUrl(url);
    
    // 오디오 재생
    await _audioPlayerService.playMp3(tokenUrl, file.fileName, '사용자 업로드');
  }
  
  // 토큰을 포함한 URL 생성
  Future<String> _getTokenUrl(String url) async {
    // API 서비스를 통해 토큰을 가져오는 로직 구현
    // 임시로 기존 URL 반환
    return url;
  }

  @override
  Widget build(BuildContext context) {
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
  
  // 현재 재생 중인 파일 UI
  Widget _buildNowPlaying() {
    return StreamBuilder<Duration>(
      stream: _audioPlayerService.audioPlayer.positionStream,
      builder: (context, snapshot) {
        final position = snapshot.data ?? Duration.zero;
        final duration = _audioPlayerService.audioPlayer.duration ?? Duration.zero;
        
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
                value: duration.inMilliseconds > 0
                    ? position.inMilliseconds / duration.inMilliseconds
                    : 0.0,
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
                      final newPosition = position - const Duration(seconds: 10);
                      _audioPlayerService.audioPlayer.seek(newPosition);
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
                          _audioPlayerService.playOrPause();
                        },
                      );
                    },
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.forward_10),
                    onPressed: () {
                      final newPosition = position + const Duration(seconds: 10);
                      _audioPlayerService.audioPlayer.seek(newPosition);
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
  
  // 오디오 파일 항목 위젯
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
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 재생 버튼
            IconButton(
              icon: Icon(
                isPlaying ? Icons.pause : Icons.play_arrow,
                color: isPlaying ? AppTheme.primaryColor : null,
              ),
              onPressed: () {
                if (isPlaying) {
                  _audioPlayerService.playOrPause();
                } else {
                  _playMp3(file);
                }
              },
            ),
          ],
        ),
        onTap: () {
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
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
  
  // 날짜 형식 변환
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}