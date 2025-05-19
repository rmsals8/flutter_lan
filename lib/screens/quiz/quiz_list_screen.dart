import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/quiz.dart';
import '../providers/quiz_provider.dart';
import '../widgets/common/loading_spinner.dart';
import '../widgets/quiz/quiz_card.dart';

class QuizListScreen extends StatefulWidget {
  const QuizListScreen({Key? key}) : super(key: key);

  @override
  State<QuizListScreen> createState() => _QuizListScreenState();
}

class _QuizListScreenState extends State<QuizListScreen> {
  @override
  void initState() {
    super.initState();
    // 화면이 로드되면 퀴즈 목록 가져오기
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<QuizProvider>(context, listen: false).fetchQuizzes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('내 퀴즈 목록'),
      ),
      body: Consumer<QuizProvider>(
        builder: (context, quizProvider, child) {
          if (quizProvider.isLoading) {
            return const LoadingSpinner(message: '퀴즈 목록을 불러오는 중...');
          }
          
          if (quizProvider.error != null) {
            return ErrorDisplay(
              message: quizProvider.error!,
              onRetry: () => quizProvider.fetchQuizzes(),
            );
          }
          
          final quizzes = quizProvider.quizzes;
          
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 새 퀴즈 생성 버튼
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('새 퀴즈 만들기'),
                      onPressed: () {
                        Navigator.pushNamed(context, '/quizzes/create');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.secondaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // 퀴즈 목록
                Expanded(
                  child: quizzes.isEmpty
                      ? _buildEmptyState()
                      : _buildQuizGrid(quizzes),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  
  // 퀴즈가 없는 경우 표시할 위젯
  Widget _buildEmptyState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.quiz_outlined,
              size: 64,
              color: AppTheme.primaryColor.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              '아직 생성된 퀴즈가 없습니다.',
              style: AppTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'PDF 파일을 선택하여 새로운 퀴즈를 만들어보세요.',
              style: AppTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('새 퀴즈 만들기'),
              onPressed: () {
                Navigator.pushNamed(context, '/quizzes/create');
              },
            ),
          ],
        ),
      ),
    );
  }
  
  // 퀴즈 그리드 위젯
  Widget _buildQuizGrid(List<Quiz> quizzes) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // 가로 2개 배치
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8, // 카드 비율 조정
      ),
      itemCount: quizzes.length,
      itemBuilder: (context, index) {
        final quiz = quizzes[index];
        return QuizCard(quiz: quiz);
      },
    );
  }
}