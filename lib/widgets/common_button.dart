import 'package:flutter/material.dart';
import '../config/theme.dart';

class CommonButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isDisabled;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double? height;
  final bool isOutlined;

  const CommonButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isDisabled = false,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height,
    this.isOutlined = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget buttonChild = isLoading
        ? Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isOutlined ? AppTheme.primaryColor : Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '로딩 중...',
                style: AppTheme.buttonText.copyWith(
                  color: isOutlined
                      ? textColor ?? AppTheme.primaryColor
                      : textColor ?? Colors.white,
                ),
              ),
            ],
          )
        : Text(
            text,
            style: AppTheme.buttonText.copyWith(
              color: isOutlined
                  ? textColor ?? AppTheme.primaryColor
                  : textColor ?? Colors.white,
            ),
          );

    if (isOutlined) {
      return SizedBox(
        width: width ?? double.infinity,
        height: height ?? 48,
        child: OutlinedButton(
          onPressed: (isDisabled || isLoading) ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: textColor ?? AppTheme.primaryColor,
            side: const BorderSide(color: AppTheme.dividerColor),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            disabledForegroundColor: AppTheme.textSecondaryColor.withOpacity(0.38),
          ),
          child: buttonChild,
        ),
      );
    } else {
      return SizedBox(
        width: width ?? double.infinity,
        height: height ?? 48,
        child: ElevatedButton(
          onPressed: (isDisabled || isLoading) ? null : onPressed,
          style: ElevatedButton.styleFrom(
            foregroundColor: textColor ?? Colors.white,
            backgroundColor: backgroundColor ?? AppTheme.primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            disabledBackgroundColor: 
                (backgroundColor ?? AppTheme.primaryColor).withOpacity(0.38),
          ),
          child: buttonChild,
        ),
      );
    }
  }
}

class GoogleSignInButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isDisabled;
  final String text;

  const GoogleSignInButton({
    Key? key,
    required this.onPressed,
    this.isLoading = false,
    this.isDisabled = false,
    this.text = '구글로 계속하기',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: (isDisabled || isLoading) ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.textSecondaryColor,
          side: const BorderSide(color: AppTheme.dividerColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        child: isLoading
            ? Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.textSecondaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '로딩 중...',
                    style: AppTheme.buttonText.copyWith(
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: Center(
                      child: Text(
                        'G',
                        style: TextStyle(
                          color: Colors.red[700],
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    text,
                    style: AppTheme.buttonText.copyWith(
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class OrDivider extends StatelessWidget {
  const OrDivider({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(right: 10.0),
            height: 1,
            color: AppTheme.dividerColor,
          ),
        ),
        Text(
          '또는',
          style: AppTheme.bodyMedium.copyWith(
            color: AppTheme.textSecondaryColor,
          ),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(left: 10.0),
            height: 1,
            color: AppTheme.dividerColor,
          ),
        ),
      ],
    );
  }
}