import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../models/quiz.dart';
import 'package:intl/intl.dart';

class QuizCard extends StatelessWidget {
  final Quiz quiz;

  const QuizCard({
    Key? key,
    required this.quiz,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/quizzes/detail',
          arguments: {'quizId': quiz.id},
        );
      },
      child: Container(
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
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 퀴즈 카드 헤더
            Container(
              padding: const EdgeInsets.all(12),
              color: AppTheme.primaryColor,
              child: Row(
                children: [
                  const Icon(
                    Icons.quiz,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      quiz.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            
            // 퀴즈 정보
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('문제 수', '${quiz.questionCount}문제'),
                  const SizedBox(height: 4),
                  _buildInfoRow(
                    '생성일', 
                    DateFormat('yyyy-MM-dd').format(quiz.createdAt),
                  ),
                  const SizedBox(height: 4),
                  _buildInfoRow(
                    '원본 파일',
                    quiz.fileName,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            
            const Spacer(),
            
            // 퀴즈 액션 버튼들
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(
                    context,
                    '상세정보',
                    Icons.info_outline,
                    AppTheme.textSecondaryColor,
                    () {
                      Navigator.pushNamed(
                        context,
                        '/quizzes/detail',
                        arguments: {'quizId': quiz.id},
                      );
                    },
                  ),
                  _buildActionButton(
                    context,
                    '퀴즈 풀기',
                    Icons.play_arrow,
                    AppTheme.primaryColor,
                    () {
                      Navigator.pushNamed(
                        context,
                        '/quizzes/take',
                        arguments: {'quizId': quiz.id},
                      );
                    },
                  ),
                  _buildActionButton(
                    context,
                    '다운로드',
                    Icons.download,
                    AppTheme.warningColor,
                    () {
                      // PDF 다운로드 로직
                      // TODO: 다운로드 기능 추가
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // 정보 행 위젯
  Widget _buildInfoRow(String label, String value, {int? maxLines}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 65,
          child: Text(
            label,
            style: AppTheme.bodySmall.copyWith(
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
            maxLines: maxLines,
            overflow: maxLines != null ? TextOverflow.ellipsis : null,
          ),
        ),
      ],
    );
  }
  
  // 액션 버튼 위젯
  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(icon, color: color),
          onPressed: onPressed,
          tooltip: label,
          constraints: const BoxConstraints(),
          padding: const EdgeInsets.all(8),
        ),
        Text(
          label,
          style: AppTheme.bodySmall.copyWith(
            color: color,
          ),
        ),
      ],
    );
  }
}