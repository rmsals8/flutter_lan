// lib/screens/alarm/mp3_selector_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/user_file.dart';
import '../../providers/file_provider.dart';

class MP3SelectorScreen extends StatefulWidget {
  const MP3SelectorScreen({Key? key}) : super(key: key);

  @override
  State<MP3SelectorScreen> createState() => _MP3SelectorScreenState();
}

class _MP3SelectorScreenState extends State<MP3SelectorScreen> {
  @override
  void initState() {
    super.initState();
    // 화면이 로드되면 오디오 파일 목록 가져오기
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FileProvider>(context, listen: false).fetchAudioFiles();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('알람음 선택'),
      ),
      body: Consumer<FileProvider>(
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
            itemCount: audioFiles.length + 1, // 기본 알람음 포함
            itemBuilder: (context, index) {
              if (index == 0) {
                // 기본 알람음
                return _buildSoundItem(
                  context,
                  '기본 알람음',
                  'assets/default_alarm.mp3',
                  isDefault: true,
                );
              } else {
                // 사용자 업로드 MP3
                final file = audioFiles[index - 1];
                return _buildSoundItem(
                  context,
                  file.fileName,
                  file.fileType == 'SCRIPT_AUDIO'
                      ? 'https://port-0-java-springboot-lan-m8dt2pjh3adde56e.sel4.cloudtype.app/api/files/download/${file.id}'
                      : 'https://port-0-java-springboot-lan-m8dt2pjh3adde56e.sel4.cloudtype.app/api/files/download/${file.id}',
                );
              }
            },
          );
        },
      ),
    );
  }
  
  // 오디오 파일이 없는 경우 표시할 위젯
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
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
              '업로드된 MP3 파일이 없습니다.\n기본 알람음을 사용하거나 MP3 파일을 업로드해주세요.',
              style: AppTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('파일 업로드'),
              onPressed: () {
                // 파일 업로드 화면으로 이동 (구현 필요)
                Navigator.pop(context);
                Navigator.pushNamed(context, '/files/upload');
              },
            ),
          ],
        ),
      ),
    );
  }
  
  // 알람음 항목 위젯
  Widget _buildSoundItem(
    BuildContext context,
    String name,
    String path, {
    bool isDefault = false,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Icon(
          isDefault ? Icons.music_note : Icons.audio_file,
          color: AppTheme.primaryColor,
        ),
        title: Text(name),
        subtitle: Text(isDefault ? '기본 알람음' : '사용자 업로드 파일'),
        trailing: const Icon(Icons.play_arrow),
        onTap: () {
          // 파일 선택 후 이전 화면으로 결과 전달
          Navigator.pop(context, {
            'name': name,
            'path': path,
          });
        },
      ),
    );
  }
}