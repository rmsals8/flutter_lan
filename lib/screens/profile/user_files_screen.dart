import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../config/theme.dart';
import '../models/user_file.dart';
import '../providers/file_provider.dart';
import '../services/file_service.dart';
import '../widgets/common/loading_spinner.dart';

class UserFilesScreen extends StatefulWidget {
  const UserFilesScreen({Key? key}) : super(key: key);

  @override
  State<UserFilesScreen> createState() => _UserFilesScreenState();
}

class _UserFilesScreenState extends State<UserFilesScreen> with SingleTickerProviderStateMixin {
  final FileService _fileService = FileService();
  late TabController _tabController;
  bool _isDeleting = false;
  final int FILE_LIMIT_PER_TYPE = 2; // 파일 타입별 최대 저장 개수 제한
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
    
    // 화면이 로드되면 파일 목록 가져오기
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFiles();
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  // 파일 로드 함수
  void _loadFiles() {
    final fileProvider = Provider.of<FileProvider>(context, listen: false);
    fileProvider.fetchAllFiles();
    fileProvider.fetchConversationFiles();
    fileProvider.fetchAudioFiles();
  }
  
  // 탭 변경 처리
  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      setState(() {});
    }
  }
  
  // 파일 다운로드 처리
  Future<void> _handleDownload(UserFile file) async {
    try {
      await _fileService.downloadFile(file.id, file.fileName);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${file.fileName} 다운로드 완료')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('다운로드 오류: ${e.toString()}')),
      );
    }
  }
  
  // 파일 삭제 처리
  Future<void> _handleDelete(UserFile file) async {
    // 사용자에게 삭제 확인 요청
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('파일 삭제'),
        content: Text('${file.fileName} 파일을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    setState(() {
      _isDeleting = true;
    });
    
    try {
      final fileProvider = Provider.of<FileProvider>(context, listen: false);
      final success = await fileProvider.deleteFile(file.id);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${file.fileName} 파일이 삭제되었습니다')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('삭제 오류: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FileProvider>(
      builder: (context, fileProvider, child) {
        final allFiles = fileProvider.allFiles;
        final conversationFiles = fileProvider.conversationFiles;
        final audioFiles = fileProvider.audioFiles;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '내 파일',
              style: AppTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            
            // 파일 타입별 저장 한도 표시
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLimitItem(
                    '대화 PDF',
                    conversationFiles.length,
                    FILE_LIMIT_PER_TYPE,
                  ),
                  const SizedBox(height: 8),
                  _buildLimitItem(
                    '오디오 파일',
                    audioFiles.length,
                    FILE_LIMIT_PER_TYPE,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // 파일 탭
            TabBar(
              controller: _tabController,
              labelColor: AppTheme.primaryColor,
              unselectedLabelColor: AppTheme.textSecondaryColor,
              indicatorColor: AppTheme.primaryColor,
              tabs: const [
                Tab(text: '모든 파일'),
                Tab(text: '대화 PDF'),
                Tab(text: '오디오 파일'),
              ],
            ),
            const SizedBox(height: 16),
            
            // 파일 목록
            Expanded(
              child: fileProvider.isLoading
                  ? const Center(child: LoadingSpinner())
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        // 모든 파일 탭
                        _buildFilesList(allFiles),
                        
                        // 대화 PDF 탭
                        _buildFilesList(conversationFiles),
                        
                        // 오디오 파일 탭
                        _buildFilesList(audioFiles),
                      ],
                    ),
            ),
            
            // 파일 정보 푸터
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                '각 유형별로 최대 ${FILE_LIMIT_PER_TYPE}개의 파일만 저장됩니다. '
                '새 파일을 저장하면 가장 오래된 파일이 자동으로 삭제됩니다. '
                '모든 파일은 생성 후 30일이 지나면 자동으로 삭제됩니다.',
                style: AppTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        );
      },
    );
  }
  
  // 파일 한도 표시 위젯
  Widget _buildLimitItem(String label, int current, int max) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: 80,
              child: Text(
                label,
                style: AppTheme.bodyMedium,
              ),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: current / max,
                  minHeight: 8,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    current >= max ? AppTheme.warningColor : AppTheme.primaryColor,
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 40,
              child: Text(
                '$current/$max',
                style: AppTheme.bodyMedium,
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  // 파일 목록 위젯
  Widget _buildFilesList(List<UserFile> files) {
    if (files.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.insert_drive_file_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              '저장된 파일이 없습니다.',
              style: AppTheme.bodyLarge,
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      itemCount: files.length,
      itemBuilder: (context, index) {
        final file = files[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            leading: Icon(
              file.fileType == 'CONVERSATION_PDF' ? Icons.picture_as_pdf : Icons.audiotrack,
              color: AppTheme.primaryColor,
              size: 32,
            ),
            title: Text(
              file.fileName,
              style: AppTheme.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  '생성일: ${DateFormat('yyyy-MM-dd').format(file.createdAt)}',
                  style: AppTheme.bodySmall,
                ),
                Text(
                  '만료일: ${DateFormat('yyyy-MM-dd').format(file.expireAt)}',
                  style: AppTheme.bodySmall,
                ),
                Text(
                  '파일 크기: ${_formatFileSize(file.fileSize)}',
                  style: AppTheme.bodySmall,
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 다운로드 버튼
                IconButton(
                  icon: const Icon(Icons.download),
                  color: AppTheme.primaryColor,
                  onPressed: _isDeleting ? null : () => _handleDownload(file),
                  tooltip: '다운로드',
                ),
                // 삭제 버튼
                IconButton(
                  icon: const Icon(Icons.delete),
                  color: AppTheme.errorColor,
                  onPressed: _isDeleting ? null : () => _handleDelete(file),
                  tooltip: '삭제',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  // 파일 크기 형식화 함수
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}