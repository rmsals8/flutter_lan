import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/quiz.dart';
import '../../models/quiz_attempt.dart';
import '../../models/quiz_question.dart';
import '../../services/quiz_service.dart';
import '../../widgets/common/loading_spinner.dart';
import '../../widgets/common/quiz/quiz_question_widget.dart';

class QuizTakeScreen extends StatefulWidget {
  const QuizTakeScreen({Key? key}) : super(key: key);

  @override
  State<QuizTakeScreen> createState() => _QuizTakeScreenState();
}

class _QuizTakeScreenState extends State<QuizTakeScreen> {
  final QuizService _quizService = QuizService();
  
  // 상태 변수들
  QuizDetail? _quizDetail;
  QuizAttempt? _currentAttempt;
  int _currentQuestionIndex = 0;
  Map<int, String> _answers = {}; // 질문 ID를 키로 사용
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;
  
  @override
  void initState() {
    super.initState();
    // 화면이 로드되면 퀴즈 시작하기
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeQuiz();
    });
  }
  
  // 퀴즈 초기화
  Future<void> _initializeQuiz() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args == null || !args.containsKey('quizId')) {
        throw Exception('퀴즈 ID가 필요합니다.');
      }
      
      final quizId = args['quizId'] as int;
      
      // 1. 퀴즈 정보 로드
      final quizDetail = await _quizService.getQuizDetails(quizId);
      
      // 2. 퀴즈 응시 시작
      final attempt = await _quizService.startQuizAttempt(quizId);
      
      // 3. 답변 맵 초기화
      final answers = <int, String>{};
      for (final question in quizDetail.questions) {
        answers[question.id] = '';
      }
      
      // 4. 로컬 스토리지에서 기존 답변 로드 (실제 구현 필요)
      // TODO: 로컬 스토리지에서 이전 답변 불러오기
      
      setState(() {
        _quizDetail = quizDetail;
        _currentAttempt = attempt;
        _answers = answers;
        _currentQuestionIndex = 0;
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
  
  // 다음 문제로 이동
  void _goToNextQuestion() {
    if (_currentQuestionIndex >= (_quizDetail?.questions.length ?? 0) - 1) return;
    
    setState(() {
      _currentQuestionIndex += 1;
    });
  }
  
  // 이전 문제로 이동
  void _goToPreviousQuestion() {
    if (_currentQuestionIndex <= 0) return;
    
    setState(() {
      _currentQuestionIndex -= 1;
    });
  }
  
  // 답변 변경 처리
  void _handleAnswerChange(int questionId, String answer) {
    setState(() {
      _answers[questionId] = answer;
    });
    
    // 로컬 스토리지에 저장 (실제 구현 필요)
    // TODO: 로컬 스토리지에 답변 저장
  }
  
  // 퀴즈 완료 처리
  Future<void> _handleCompleteQuiz() async {
    if (_currentAttempt == null || _quizDetail == null) return;
    
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    
    try {
      // 전체 답변 목록 생성
      final answersList = _answers.entries.map((entry) {
        return AnswerSubmit(
          questionId: entry.key,
          userAnswer: entry.value,
        );
      }).toList();
      
      // 답변 일괄 제출
      await _quizService.submitAllAnswers(_currentAttempt!.id, answersList);
      
      // 퀴즈 응시 완료
      final completedAttempt = await _quizService.completeQuizAttempt(_currentAttempt!.id);
      
      // 결과 화면으로 이동
      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          '/quizzes/results',
          arguments: {
            'quizId': _quizDetail!.id,
            'attemptId': completedAttempt.id,
          },
        );
      }
      
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('퀴즈 풀기'),
        ),
        body: const LoadingSpinner(message: '퀴즈를 준비하는 중...'),
      );
    }
    
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('퀴즈 풀기'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: ErrorDisplay(
          message: _error!,
          onRetry: _initializeQuiz,
        ),
      );
    }
    
    if (_quizDetail == null || _currentAttempt == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('퀴즈 풀기'),
        ),
        body: const Center(
          child: Text('퀴즈를 불러올 수 없습니다.'),
        ),
      );
    }
    
    // 현재 문제
    final currentQuestion = _quizDetail!.questions[_currentQuestionIndex];
    final totalQuestions = _quizDetail!.questions.length;
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(_quizDetail!.title),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            // 퀴즈 종료 확인 다이얼로그
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('퀴즈 종료'),
                content: const Text('정말 퀴즈를 종료하시겠습니까? 현재까지의 답변은 저장됩니다.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('취소'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context); // 다이얼로그 닫기
                      Navigator.pop(context); // 퀴즈 화면 닫기
                    },
                    child: const Text('종료'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 진행 상태 표시
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '문제 ${_currentQuestionIndex + 1} / $totalQuestions',
                  style: AppTheme.bodyLarge.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${((_currentQuestionIndex + 1) / totalQuestions * 100).toInt()}%',
                  style: AppTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // 진행 바
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: (_currentQuestionIndex + 1) / totalQuestions,
                minHeight: 8,
                backgroundColor: Colors.grey[300],
                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              ),
            ),
            const SizedBox(height: 16),
            
            // 문제 카드
            Expanded(
              child: Container(
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
                child: QuizQuestionWidget(
                  question: currentQuestion,
                  answer: _answers[currentQuestion.id] ?? '',
                  onAnswerChange: (answer) => _handleAnswerChange(currentQuestion.id, answer),
                  disabled: _isSubmitting,
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // 오류 메시지
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.errorColor),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppTheme.errorColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.errorColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // 이전/다음 버튼
            Row(
              children: [
                // 이전 버튼
                if (_currentQuestionIndex > 0) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('이전'),
                      onPressed: _isSubmitting ? null : _goToPreviousQuestion,
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                
                // 다음 또는 완료 버튼
                Expanded(
                  flex: 2,
                  child: _currentQuestionIndex < totalQuestions - 1
                      ? ElevatedButton.icon(
                          icon: const Icon(Icons.arrow_forward),
                          label: const Text('다음'),
                          onPressed: _isSubmitting ? null : _goToNextQuestion,
                        )
                      : ElevatedButton(
                          onPressed: _isSubmitting ? null : _handleCompleteQuiz,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.secondaryColor,
                          ),
                          child: _isSubmitting
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Text('제출 중...'),
                                  ],
                                )
                              : const Text('퀴즈 완료'),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}