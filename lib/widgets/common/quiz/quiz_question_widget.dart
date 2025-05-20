import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../models/quiz_question.dart';

class QuizQuestionWidget extends StatelessWidget {
  final QuizQuestion question;
  final String answer;
  final Function(String) onAnswerChange;
  final bool disabled;

  const QuizQuestionWidget({
    Key? key,
    required this.question,
    required this.answer,
    required this.onAnswerChange,
    this.disabled = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 문제 텍스트와 타입 뱃지
        Row(
          children: [
            Expanded(
              child: Text(
                question.questionText,
                style: AppTheme.titleMedium,
              ),
            ),
            Container(
              margin: const EdgeInsets.only(left: 8),
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
        const SizedBox(height: 24),
        
        // 객관식 또는 주관식에 따른 UI
        question.isMultipleChoice
            ? _buildMultipleChoiceOptions()
            : _buildShortAnswerInput(),
      ],
    );
  }
  
  // 객관식 옵션 위젯
  Widget _buildMultipleChoiceOptions() {
    if (question.options == null || question.options!.isEmpty) {
      return const Text('선택지가 없습니다.');
    }
    
    return Expanded(
      child: ListView.builder(
        itemCount: question.options!.length,
        itemBuilder: (context, index) {
          final option = question.options![index];
          final isSelected = option == answer;
          
          return GestureDetector(
            onTap: disabled ? null : () => onAnswerChange(option),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? AppTheme.primaryColor : Colors.grey[300]!,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  // 라디오 버튼 UI
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? AppTheme.primaryColor : Colors.white,
                      border: Border.all(
                        color: isSelected ? AppTheme.primaryColor : Colors.grey[400]!,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check,
                            size: 14,
                            color: Colors.white,
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      option,
                      style: AppTheme.bodyMedium.copyWith(
                        fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                        color: isSelected 
                            ? AppTheme.primaryColor 
                            : AppTheme.textPrimaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  
  // 주관식 입력 위젯
  Widget _buildShortAnswerInput() {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: TextFormField(
          initialValue: answer,
          onChanged: onAnswerChange,
          enabled: !disabled,
          maxLines: null,
          expands: true,
          decoration: const InputDecoration(
            hintText: '답변을 입력하세요...',
            contentPadding: EdgeInsets.all(16),
            border: InputBorder.none,
          ),
          style: AppTheme.bodyMedium,
        ),
      ),
    );
  }
}