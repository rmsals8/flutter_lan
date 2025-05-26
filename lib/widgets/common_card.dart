import 'package:flutter/material.dart';
import '../config/theme.dart';

class CardContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final EdgeInsetsGeometry padding;
  
  const CardContainer({
    Key? key,
    required this.child,
    this.width,
    this.padding = const EdgeInsets.all(24.0),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? double.infinity,
      constraints: const BoxConstraints(maxWidth: 450),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
      padding: padding,
      child: child,
    );
  }
}

class ErrorMessageBox extends StatelessWidget {
  final String message;

  const ErrorMessageBox({
    Key? key,
    required this.message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (message.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.errorColor),
      ),
      child: Text(
        message,
        style: AppTheme.bodyMedium.copyWith(
          color: AppTheme.errorColor,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class SuccessMessageBox extends StatelessWidget {
  final String message;

  const SuccessMessageBox({
    Key? key,
    required this.message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (message.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.secondaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.secondaryColor),
      ),
      child: Text(
        message,
        style: AppTheme.bodyMedium.copyWith(
          color: AppTheme.secondaryColor,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class CustomCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?> onChanged;
  final String text;
  final bool isRequired;

  const CustomCheckbox({
    Key? key,
    required this.value,
    required this.onChanged,
    required this.text,
    this.isRequired = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: GestureDetector(
            onTap: () => onChanged(!value),
            child: RichText(
              text: TextSpan(
                text: text,
                style: AppTheme.bodyMedium,
                children: isRequired
                    ? [
                        TextSpan(
                          text: ' *',
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppTheme.errorColor,
                          ),
                        )
                      ]
                    : null,
              ),
            ),
          ),
        ),
      ],
    );
  }
}