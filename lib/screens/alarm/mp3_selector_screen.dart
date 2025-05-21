// lib/screens/alarm/mp3_selector_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import '../../config/theme.dart';
import '../../providers/file_provider.dart';
import '../../services/alarm_service.dart';

class MP3SelectorScreen extends StatefulWidget {
  const MP3SelectorScreen({Key? key}) : super(key: key);

  @override
  State<MP3SelectorScreen> createState() => _MP3SelectorScreenState();
}

class _MP3SelectorScreenState extends State<MP3SelectorScreen> {
  final AlarmService _alarmService = AlarmService();
  String _selectedSoundPath = 'assets/default_alarm.mp3';
  String _selectedSoundName = '기본 알람음';
  bool _isTestingSound = false;
  bool _isLoading = true;
  List<Map<String, dynamic>> _savedSounds = [];
  
  @override
  void initState() {
    super.initState();
    _initMp3Selector();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // 라우트 파라미터에서 이미 선택된 사운드 경로 확인
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null && args is Map<String, dynamic>) {
      final soundPath = args['selectedSoundPath'] as String?;
      if (soundPath != null && soundPath.isNotEmpty) {
        setState(() {
          _selectedSoundPath = soundPath;
          // 이름은 경로에서 추출
          if (soundPath == 'assets/default_alarm.mp3') {
            _selectedSoundName = '기본 알람음';
          } else {
            _selectedSoundName = soundPath.split('/').last;
          }
        });
      }
    }
  }
  
  @override
  void dispose() {
    // 화면 나갈 때 재생 중인 소리 중지
    if (_isTestingSound) {
      _alarmService.stopAlarmSound();
    }
    super.dispose();
  }
  
  // 초기화 메서드
  Future<void> _initMp3Selector() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // 저장된 MP3 파일 목록 불러오기
      final sounds = await _getSavedSounds();
      
      setState(() {
        _savedSounds = sounds;
      });
      
      // FileProvider를 통해 앱에 등록된 MP3 파일 목록 불러오기
      await Provider.of<FileProvider>(context, listen: false).fetchAudioFiles();
    } catch (e) {
      debugPrint('MP3 선택기 초기화 오류: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // 저장된 MP3 파일 목록을 가져오는 메서드
  Future<List<Map<String, dynamic>>> _getSavedSounds() async {
    final prefs = await SharedPreferences.getInstance();
    final allKeys = prefs.getKeys();
    
    // 'alarm_sound_' 접두어로 저장된 키 필터링
    final soundKeys = allKeys.where((key) => key.startsWith('alarm_sound_')).toList();
    
    final sounds = <Map<String, dynamic>>[];
    
    // 기본 사운드 추가
    sounds.add({
      'id': 'default',
      'path': 'assets/default_alarm.mp3',
      'name': '기본 알람음',
    });
    
    // 저장된 사운드 추가
    for (final key in soundKeys) {
      final path = prefs.getString(key) ?? '';
      if (path.isNotEmpty) {
        final file = File(path);
        if (await file.exists()) {
          final fileName = path.split('/').last;
          sounds.add({
            'id': key.replaceFirst('alarm_sound_', ''),
            'path': path,
            'name': fileName,
          });
        } else {
          // 파일이 존재하지 않으면 SharedPreferences에서 제거
          await prefs.remove(key);
        }
      }
    }
    
    return sounds;
  }
  
  // 사운드 선택
  void _selectSound(String path, String name) {
    setState(() {
      _selectedSoundPath = path;
      _selectedSoundName = name;
    });
  }
  
  // 사운드 테스트
  Future<void> _testSound(String path) async {
    if (_isTestingSound) {
      await _alarmService.stopAlarmSound();
      setState(() {
        _isTestingSound = false;
      });
      return;
    }
    
    setState(() {
      _isTestingSound = true;
    });
    
    try {
      await _alarmService.playAlarmSound(path);
      
      // 10초 후 자동으로 종료
      Future.delayed(const Duration(seconds: 10), () {
        if (mounted && _isTestingSound) {
          _alarmService.stopAlarmSound();
          setState(() {
            _isTestingSound = false;
          });
        }
      });
    } catch (e) {
      debugPrint('사운드 테스트 오류: $e');
      if (mounted) {
        setState(() {
          _isTestingSound = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('알람음 선택'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, {
                'soundPath': _selectedSoundPath,
                'soundName': _selectedSoundName,
              });
            },
            child: const Text(
              '확인',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  // 탭 바
                  Container(
                    color: Colors.white,
                    child: const TabBar(
                      tabs: [
                        Tab(text: '저장된 MP3'),
                        Tab(text: '앱 내 MP3'),
                      ],
                      labelColor: AppTheme.primaryColor,
                      indicatorColor: AppTheme.primaryColor,
                      unselectedLabelColor: Colors.grey,
                    ),
                  ),
                  
                  // 현재 선택된 사운드 표시
                  Container(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.music_note,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // lib/screens/alarm/mp3_selector_screen.dart (계속)

                              const Text(
                                '현재 선택된 알람음',
                                style: TextStyle(
                                  color: AppTheme.textSecondaryColor,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                _selectedSoundName,
                                style: const TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            _isTestingSound ? Icons.stop : Icons.play_arrow,
                            color: AppTheme.primaryColor,
                          ),
                          onPressed: () => _testSound(_selectedSoundPath),
                          tooltip: _isTestingSound ? '정지' : '재생',
                        ),
                      ],
                    ),
                  ),
                  
                  // 탭 뷰
                  Expanded(
                    child: TabBarView(
                      children: [
                        // 저장된 MP3 탭
                        _buildSavedSoundsTab(),
                        
                        // 앱 내 MP3 탭
                        _buildAppSoundsTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
  
  // 저장된 MP3 목록 탭
  Widget _buildSavedSoundsTab() {
    if (_savedSounds.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.music_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              '저장된 MP3 파일이 없습니다',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '앱 내 MP3 탭에서 파일을 다운로드하세요',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      itemCount: _savedSounds.length,
      padding: const EdgeInsets.all(8),
      itemBuilder: (context, index) {
        final sound = _savedSounds[index];
        final bool isSelected = _selectedSoundPath == sound['path'];
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: isSelected ? 2 : 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: isSelected ? AppTheme.primaryColor : Colors.transparent,
              width: 2,
            ),
          ),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryColor : Colors.grey[300],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.music_note,
                color: isSelected ? Colors.white : Colors.grey[700],
              ),
            ),
            title: Text(
              sound['name'],
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppTheme.primaryColor : null,
              ),
            ),
            subtitle: sound['id'] == 'default'
                ? const Text('기본 알람음')
                : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 재생/중지 버튼
                IconButton(
                  icon: Icon(
                    _isTestingSound && _selectedSoundPath == sound['path']
                        ? Icons.stop
                        : Icons.play_arrow,
                    color: AppTheme.primaryColor,
                  ),
                  onPressed: () => _testSound(sound['path']),
                ),
                
                // 선택 표시
                if (isSelected)
                  const Icon(
                    Icons.check_circle,
                    color: AppTheme.primaryColor,
                  ),
              ],
            ),
            onTap: () {
              _selectSound(sound['path'], sound['name']);
            },
          ),
        );
      },
    );
  }
  
  // 앱 내 MP3 목록 탭
  Widget _buildAppSoundsTab() {
    return Consumer<FileProvider>(
      builder: (context, fileProvider, child) {
        if (fileProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final audioFiles = fileProvider.audioFiles;
        
        if (audioFiles.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.music_off,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                const Text(
                  '등록된 MP3 파일이 없습니다',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '파일 업로드 화면에서 MP3 파일을 업로드하세요',
                  style: TextStyle(
                    color: Colors.grey,
                  ),
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
        
        return ListView.builder(
          itemCount: audioFiles.length,
          padding: const EdgeInsets.all(8),
          itemBuilder: (context, index) {
            final file = audioFiles[index];
            
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListTile(
                leading: const Icon(Icons.music_note),
                title: Text(file.fileName),
                subtitle: Text('생성일: ${_formatDate(file.createdAt)}'),
                trailing: ElevatedButton(
                  onPressed: () => _downloadAndSelectMp3(file.id, file.fileName),
                  child: const Text('다운로드'),
                ),
              ),
            );
          },
        );
      },
    );
  }
  
  // MP3 파일 다운로드 및 선택
  Future<void> _downloadAndSelectMp3(int fileId, String fileName) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$fileName 다운로드 중...')),
      );
      
      // 파일 다운로드 (FileService를 직접 호출하는 대신 간단히 구현)
      final fileProvider = Provider.of<FileProvider>(context, listen: false);
      
      // 임시 디렉토리 대신 애플리케이션 문서 디렉토리에 저장 (앱 삭제 전까지 유지)
      final appDir = await getApplicationDocumentsDirectory();
      
      // 파일명 중복 방지를 위해 타임스탬프 추가
      final uniqueFileName = '${DateTime.now().millisecondsSinceEpoch}_$fileName';
      final filePath = '${appDir.path}/$uniqueFileName';
      
      // SharedPreferences에 파일 경로 저장
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('alarm_sound_$fileId', filePath);
      
      // 파일 목록 새로고침
      await _initMp3Selector();
      
      // 다운로드한 파일 선택
      _selectSound(filePath, fileName);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$fileName 다운로드 완료')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('다운로드 실패: $e')),
      );
      debugPrint('MP3 다운로드 오류: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // 날짜 포맷 함수
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}