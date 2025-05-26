import 'package:flutter/material.dart';
import '../../../config/theme.dart';

class QuizOptionWidget extends StatelessWidget {
  final String option;
  final bool isSelected;
  final Function(String) onSelect;
  final bool disabled;

  const QuizOptionWidget({
    Key? key,
    required this.option,
    required this.isSelected,
    required this.onSelect,
    this.disabled = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: disabled ? null : () => onSelect(option),
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
  }
}