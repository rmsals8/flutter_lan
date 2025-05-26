import 'package:flutter/material.dart';
import '../config/theme.dart';

class CommonTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final String? labelText;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final Function(String)? onChanged;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool enabled;
  final bool? isValid;
  final String? validationMessage;

  const CommonTextField({
    Key? key,
    required this.controller,
    required this.hintText,
    this.labelText,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.onChanged,
    this.prefixIcon,
    this.suffixIcon,
    this.enabled = true,
    this.isValid,
    this.validationMessage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (labelText != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              labelText!,
              style: AppTheme.bodyMedium.copyWith(
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(
                color: isValid == null 
                    ? AppTheme.dividerColor 
                    : (isValid! ? AppTheme.secondaryColor : AppTheme.errorColor),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(
                color: isValid == null 
                    ? AppTheme.dividerColor 
                    : (isValid! ? AppTheme.secondaryColor : AppTheme.errorColor),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(
                color: isValid == null 
                    ? AppTheme.primaryColor 
                    : (isValid! ? AppTheme.secondaryColor : AppTheme.errorColor),
                width: 2,
              ),
            ),
          ),
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          onChanged: onChanged,
          enabled: enabled,
          style: AppTheme.bodyLarge,
        ),
        if (validationMessage != null && validationMessage!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 5.0, left: 4.0),
            child: Text(
              validationMessage!,
              style: AppTheme.bodySmall.copyWith(
                color: isValid == true ? AppTheme.secondaryColor : AppTheme.errorColor,
              ),
            ),
          ),
      ],
    );
  }
}