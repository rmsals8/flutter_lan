import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/user_file.dart';
import '../providers/file_provider.dart';
import '../providers/quiz_provider.dart';
import '../widgets/common/loading_spinner.dart';

class QuizGeneratorScreen extends StatefulWidget {
  const QuizGeneratorScreen({Key? key}) : super(key: key);

  @override
  State<QuizGeneratorScreen> createState() => _QuizGeneratorScreenState();
}

class _QuizGeneratorScreenState extends State<QuizGeneratorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  
  int? _selectedFileId;
  int _numMultipleChoice = 5;
  int _numShortAnswer = 3;
  bool _isGenerating = false;
  
  @override
  void initState() {
    super.initState();
    // 화면이 로드되면 대화 PDF 파일 목록 가져오기
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FileProvider>(context, listen: false).fetchConversationFiles();
    });
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }
  
  // 파일 선택 처리
  void _handleFileSelect(int? fileId, String? fileName) {
    setState(() {
      _selectedFileId = fileId;
      
      // 파일명에서 제목 자동 생성
      if (fileId != null && fileName != null) {
        // ".pdf" 부분 제거 후 " 퀴즈" 추가
        String title = fileName.endsWith('.pdf')
            ? fileName.substring(0, fileName.length - 4)
            : fileName;
        
        _titleController.text = '$title 퀴즈';
      } else {
        _titleController.text = '';
      }
    });
  }
  
  // 퀴즈 생성 처리
  Future<void> _handleGenerateQuiz() async {
    if (!_formKey.currentState!.validate() || _selectedFileId == null) {
      return;
    }
    
    setState(() {
      _isGenerating = true;
    });
    
    try {
      final quizProvider = Provider.of<QuizProvider>(context, listen: false);
      final quiz = await quizProvider.generateQuiz(
        _selectedFileId!,
        _titleController.text,
        _numMultipleChoice,
        _numShortAnswer,
      );
      
      if (quiz != null && mounted) {
        // 생성된 퀴즈의 상세 페이지로 이동
        Navigator.pushReplacementNamed(
          context,
          '/quizzes/detail',
          arguments: {'quizId': quiz.id},
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('퀴즈 생성 오류: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('퀴즈 생성'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<FileProvider>(
        builder: (context, fileProvider, child) {
          if (fileProvider.isLoading) {
            return const LoadingSpinner(message: 'PDF 파일 목록을 불러오는 중...');
          }
          
          final conversationFiles = fileProvider.conversationFiles;
          
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // PDF 파일 선택
                    Text(
                      'PDF 파일 선택',
                      style: AppTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    
                    if (conversationFiles.isEmpty)
                      _buildEmptyFilesList()
                    else
                      _buildFilesList(conversationFiles),
                    
                    const SizedBox(height: 24),
                    
                    // 퀴즈 제목
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: '퀴즈 제목',
                        hintText: '퀴즈 제목을 입력하세요',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '퀴즈 제목을 입력해주세요';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    
                    // 문제 유형 설정
                    Text(
                      '문제 개수 설정',
                      style: AppTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '객관식 문제',
                                style: AppTheme.bodyMedium,
                              ),
                              const SizedBox(height: 8),
                              _buildNumberSelector(
                                value: _numMultipleChoice,
                                min: 1,
                                max: 15,
                                onChanged: (value) {
                                  setState(() {
                                    _numMultipleChoice = value;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '주관식 문제',
                                style: AppTheme.bodyMedium,
                              ),
                              const SizedBox(height: 8),
                              _buildNumberSelector(
                                value: _numShortAnswer,
                                min: 1,
                                max: 10,
                                onChanged: (value) {
                                  setState(() {
                                    _numShortAnswer = value;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    
                    // 생성 버튼
                    Center(
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isGenerating || _selectedFileId == null
                              ? null
                              : _handleGenerateQuiz,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _isGenerating
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Text('퀴즈 생성 중...'),
                                  ],
                                )
                              : const Text('퀴즈 생성하기'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // 작동 방식 설명
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.dividerColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            '작동 방식',
                            style: AppTheme.titleSmall,
                          ),
                          SizedBox(height: 8),
                          Text(
                            '선택한 PDF 파일의 내용을 분석하여 객관식 및 주관식 문제를 자동으로 생성합니다. '
                            '생성된 퀴즈는 온라인에서 풀거나 PDF로 다운로드할 수 있습니다.',
                            style: AppTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
  
  // 파일이 없는 경우 표시할 위젯
  Widget _buildEmptyFilesList() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.insert_drive_file_outlined,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'PDF 파일이 없습니다.',
            style: AppTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            '먼저 PDF 파일을 업로드해주세요.',
            style: AppTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  // 파일 목록 위젯
  Widget _buildFilesList(List<UserFile> files) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 300),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: files.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final file = files[index];
          final isSelected = _selectedFileId == file.id;
          
          return ListTile(
            title: Text(
              file.fileName,
              style: AppTheme.bodyMedium.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            subtitle: Text(
              '생성일: ${_formatDate(file.createdAt)}',
              style: AppTheme.bodySmall,
            ),
            leading: const Icon(Icons.picture_as_pdf, color: AppTheme.primaryColor),
            selected: isSelected,
            selectedTileColor: AppTheme.primaryColor.withOpacity(0.1),
            onTap: () => _handleFileSelect(file.id, file.fileName),
          );
        },
      ),
    );
  }
  
  // 숫자 선택기 위젯
  Widget _buildNumberSelector({
    required int value,
    required int min,
    required int max,
    required Function(int) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Row(
        children: [
          // 감소 버튼
          IconButton(
            icon: const Icon(Icons.remove),
            onPressed: value <= min 
                ? null 
                : () => onChanged(value - 1),
            color: value <= min 
                ? Colors.grey 
                : AppTheme.primaryColor,
          ),
          
          // 현재 값
          Expanded(
            child: Text(
              value.toString(),
              style: AppTheme.bodyLarge.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          // 증가 버튼
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: value >= max 
                ? null 
                : () => onChanged(value + 1),
            color: value >= max 
                ? Colors.grey 
                : AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }
  
  // 날짜 포맷팅 헬퍼 함수
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}