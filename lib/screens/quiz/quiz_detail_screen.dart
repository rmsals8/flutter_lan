import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:open_file/open_file.dart';
import 'package:intl/intl.dart';
import '../config/theme.dart';
import '../models/quiz.dart';
import '../providers/quiz_provider.dart';
import '../services/file_service.dart';
import '../widgets/common/loading_spinner.dart';

class QuizDetailScreen extends StatefulWidget {
  const QuizDetailScreen({Key? key}) : super(key: key);

  @override
  State<QuizDetailScreen> createState() => _QuizDetailScreenState();
}

class _QuizDetailScreenState extends State<QuizDetailScreen> {
  final FileService _fileService = FileService();
  bool _isDownloading = false;
  
  @override
  void initState() {
    super.initState();
    // 화면이 로드되면 퀴즈 상세 정보 가져오기
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args.containsKey('quizId')) {
        final quizId = args['quizId'] as int;
        Provider.of<QuizProvider>(context, listen: false).fetchQuizDetail(quizId);
      }
    });
  }

  // PDF 다운로드 및 열기
  Future<void> _downloadAndOpenPdf(int quizId, String fileName) async {
    setState(() {
      _isDownloading = true;
    });
    
    try {
      final filePath = await _fileService.downloadAndOpenPdf(quizId, '${fileName}_with_answers.pdf');
      // PDF 파일 열기
      await OpenFile.open(filePath);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF 다운로드 오류: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('퀴즈 상세 정보'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<QuizProvider>(
        builder: (context, quizProvider, child) {
          if (quizProvider.isLoading) {
            return const LoadingSpinner(message: '퀴즈 정보를 불러오는 중...');
          }
          
          if (quizProvider.error != null) {
            return ErrorDisplay(
              message: quizProvider.error!,
              onRetry: () {
                final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
                if (args != null && args.containsKey('quizId')) {
                  final quizId = args['quizId'] as int;
                  quizProvider.fetchQuizDetail(quizId);
                }
              },
            );
          }
          
          final quizDetail = quizProvider.currentQuizDetail;
          
          if (quizDetail == null) {
            return const Center(
              child: Text('퀴즈 정보를 찾을 수 없습니다.'),
            );
          }
          
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 퀴즈 제목
                  Text(
                    quizDetail.title,
                    style: AppTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  
                  // 퀴즈 정보 카드
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
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
                        _buildInfoRow('문제 수', '${quizDetail.questions.length}문제'),
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          '생성일', 
                          DateFormat('yyyy년 MM월 dd일').format(quizDetail.createdAt),
                        ),
                        const SizedBox(height: 8),
                        _buildInfoRow('원본 파일', quizDetail.fileName),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // 퀴즈 액션 버튼들
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('퀴즈 풀기'),
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              '/quizzes/take',
                              arguments: {'quizId': quizDetail.id},
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.download),
                          label: const Text('PDF 다운로드'),
                          onPressed: _isDownloading 
                              ? null 
                              : () => _downloadAndOpenPdf(quizDetail.id, quizDetail.title),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.warningColor,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // 문제 미리보기 섹션
                  Text(
                    '문제 미리보기',
                    style: AppTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  
                  // 문제 목록
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: quizDetail.questions.length,
                    itemBuilder: (context, index) {
                      final question = quizDetail.questions[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 문제 번호
                            Container(
                              width: 30,
                              height: 30,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.primaryColor,
                              ),
                              child: Center(
                                child: Text(
                                  '#${index + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    question.questionText,
                                    style: AppTheme.bodyMedium.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      question.isMultipleChoice ? '객관식' : '주관식',
                                      style: AppTheme.bodySmall,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  
  // 정보 행 위젯
  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTheme.bodyMedium.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}