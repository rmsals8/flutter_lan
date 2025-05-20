import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../models/quiz_attempt.dart';
import '../../models/quiz_question.dart';
import '../../services/quiz_service.dart';
import '../../widgets/common/loading_spinner.dart';

class QuizResultsScreen extends StatefulWidget {
  const QuizResultsScreen({Key? key}) : super(key: key);

  @override
  State<QuizResultsScreen> createState() => _QuizResultsScreenState();
}

class _QuizResultsScreenState extends State<QuizResultsScreen> {
  final QuizService _quizService = QuizService();
  
  // 상태 변수들
  QuizAttemptResult? _result;
  List<AnswerResult>? _answers;
  Map<int, QuizQuestion>? _questionsMap;
  bool _isLoading = true;
  String? _error;
  
  @override
  void initState() {
    super.initState();
    // 화면이 로드되면 퀴즈 결과 가져오기
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadQuizResults();
    });
  }
  
  // 퀴즈 결과 로드
  Future<void> _loadQuizResults() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args == null || !args.containsKey('attemptId') || !args.containsKey('quizId')) {
        throw Exception('퀴즈 ID와 응시 ID가 필요합니다.');
      }
      
      final quizId = args['quizId'] as int;
      final attemptId = args['attemptId'] as int;
      
      // 1. 퀴즈 결과 가져오기
      final result = await _quizService.getQuizAttemptResult(attemptId);
      
      // 2. 퀴즈 상세 정보 가져오기 (문제별 데이터를 위해)
      final quizDetail = await _quizService.getQuizDetails(quizId);
      
      // 3. 문제 ID -> 문제 객체 맵 생성
      final questionsMap = <int, QuizQuestion>{};
      for (final question in quizDetail.questions) {
        questionsMap[question.id] = question;
      }
      
      // 4. 퀴즈 답변 목록 가져오기
      final answers = await _quizService.getQuizAttemptAnswers(attemptId);
      
      setState(() {
        _result = result;
        _answers = answers;
        _questionsMap = questionsMap;
      });
      
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('퀴즈 결과'),
        ),
        body: const LoadingSpinner(message: '결과를 불러오는 중...'),
      );
    }
    
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('퀴즈 결과'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: ErrorDisplay(
          message: _error!,
          onRetry: _loadQuizResults,
        ),
      );
    }
    
    if (_result == null || _answers == null || _questionsMap == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('퀴즈 결과'),
        ),
        body: const Center(
          child: Text('결과를 불러올 수 없습니다.'),
        ),
      );
    }
    
    final correctCount = _answers!.where((answer) => answer.isCorrect).length;
    final totalQuestions = _result!.totalQuestions;
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('퀴즈 결과'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pushNamedAndRemoveUntil(
            context,
            '/quizzes',
            (route) => false,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                '퀴즈 결과',
                style: AppTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              // 점수 카드
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
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
                    Text(
                      _result!.quizTitle,
                      style: AppTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      '${_result!.score}%',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$correctCount / $totalQuestions 정답',
                      style: AppTheme.bodyLarge,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildScoreDetail(
                          Icons.check_circle,
                          '$correctCount 정답',
                          AppTheme.secondaryColor,
                        ),
                        const SizedBox(width: 24),
                        _buildScoreDetail(
                          Icons.cancel,
                          '${totalQuestions - correctCount} 오답',
                          AppTheme.errorColor,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // 답변 요약 테이블
              Container(
                width: double.infinity,
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '답변 요약',
                      style: AppTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    
                    // 답변 테이블
                    Table(
                      border: TableBorder.all(
                        color: Colors.grey[300]!,
                        width: 1,
                      ),
                      columnWidths: const {
                        0: FlexColumnWidth(0.5), // 문제 번호
                        1: FlexColumnWidth(3),   // 문제
                        2: FlexColumnWidth(1),   // 내 답변
                        3: FlexColumnWidth(1),   // 정답
                        4: FlexColumnWidth(0.8), // 결과
                      },
                      children: [
                        // 테이블 헤더
                        TableRow(
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                          ),
                          children: const [
                            _TableCell('#', isHeader: true),
                            _TableCell('문제', isHeader: true),
                            _TableCell('내 답변', isHeader: true),
                            _TableCell('정답', isHeader: true),
                            _TableCell('결과', isHeader: true),
                          ],
                        ),
                        
                        // 테이블 데이터 행
                        ..._answers!.asMap().entries.map((entry) {
                          final index = entry.key;
                          final answer = entry.value;
                          final question = _questionsMap![answer.questionId];
                          
                          if (question == null) {
                            return TableRow(
                              children: [
                                _TableCell('${index + 1}'),
                                const _TableCell('문제 정보 없음'),
                                _TableCell(answer.userAnswer),
                                const _TableCell('-'),
                                _TableCell(
                                  answer.isCorrect ? '정답' : '오답',
                                  textColor: answer.isCorrect 
                                      ? AppTheme.secondaryColor 
                                      : AppTheme.errorColor,
                                ),
                              ],
                            );
                          }
                          
                          return TableRow(
                            decoration: BoxDecoration(
                              color: answer.isCorrect 
                                  ? AppTheme.secondaryColor.withOpacity(0.1)
                                  : AppTheme.errorColor.withOpacity(0.1),
                            ),
                            children: [
                              _TableCell('${index + 1}'),
                              _TableCell(question.questionText),
                              _TableCell(
                                answer.userAnswer.isEmpty ? '미응답' : answer.userAnswer,
                                textColor: answer.userAnswer.isEmpty 
                                    ? Colors.grey 
                                    : null,
                                fontStyle: answer.userAnswer.isEmpty 
                                    ? FontStyle.italic 
                                    : null,
                              ),
                              _TableCell(question.correctAnswer),
                              _TableCell(
                                answer.isCorrect ? '정답' : '오답',
                                textColor: answer.isCorrect 
                                    ? AppTheme.secondaryColor 
                                    : AppTheme.errorColor,
                              ),
                            ],
                          );
                        }).toList(),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // 액션 버튼들
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.home),
                      label: const Text('퀴즈 목록으로'),
                      onPressed: () => Navigator.pushNamedAndRemoveUntil(
                        context, 
                        '/quizzes', 
                        (route) => false,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('다시 시도'),
                      onPressed: () {
                        Navigator.pushReplacementNamed(
                          context,
                          '/quizzes/take',
                          arguments: {'quizId': _result!.quizId},
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.warningColor,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // 점수 세부 정보 위젯
  Widget _buildScoreDetail(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(
          icon,
          color: color,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: AppTheme.bodyMedium.copyWith(
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// 테이블 셀 위젯
class _TableCell extends StatelessWidget {
  final String text;
  final bool isHeader;
  final Color? textColor;
  final FontStyle? fontStyle;

  const _TableCell(
    this.text, {
    this.isHeader = false,
    this.textColor,
    this.fontStyle,
  });

  @override
  Widget build(BuildContext context) {
    return TableCell(
      verticalAlignment: TableCellVerticalAlignment.middle,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          text,
          style: (isHeader ? AppTheme.bodyMedium : AppTheme.bodySmall).copyWith(
            color: isHeader ? Colors.white : textColor,
            fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
            fontStyle: fontStyle,
          ),
          textAlign: isHeader ? TextAlign.center : TextAlign.left,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}