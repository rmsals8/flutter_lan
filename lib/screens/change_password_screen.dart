import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../services/auth_service.dart';
import '../widgets/common_button.dart';
import '../widgets/common_text_field.dart';
import '../widgets/common_card.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({Key? key}) : super(key: key);

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final AuthService _authService = AuthService();
  
  String _errorMessage = '';
  String _successMessage = '';
  bool _isLoading = false;
  
  // 유효성 검사 상태
  Map<String, Map<String, dynamic>> _validations = {
    'newPassword': {'valid': false, 'message': ''},
    'confirmPassword': {'valid': false, 'message': ''},
  };

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // 비밀번호 유효성 검사
  void _validatePassword(String value) {
    final hasLowerCase = RegExp(r'[a-z]').hasMatch(value);
    final hasUpperCase = RegExp(r'[A-Z]').hasMatch(value);
    final hasNumber = RegExp(r'[0-9]').hasMatch(value);
    final hasSpecialChar = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value);
    final isLongEnough = value.length >= 8;
    
    final isValid = hasLowerCase && hasUpperCase && hasNumber && hasSpecialChar && isLongEnough;
    
    setState(() {
      _validations['newPassword'] = {
        'valid': isValid,
        'message': isValid 
            ? '강력한 비밀번호입니다.' 
            : '비밀번호는 8자 이상이어야 하며, 대문자, 소문자, 숫자, 특수문자를 모두 포함해야 합니다.',
        'hasLowerCase': hasLowerCase,
        'hasUpperCase': hasUpperCase,
        'hasNumber': hasNumber,
        'hasSpecialChar': hasSpecialChar,
        'isLongEnough': isLongEnough,
      };
      
      // 확인 비밀번호 유효성도 업데이트
      if (_confirmPasswordController.text.isNotEmpty) {
        _validateConfirmPassword(_confirmPasswordController.text);
      }
    });
  }

  // 확인 비밀번호 유효성 검사
  void _validateConfirmPassword(String value) {
    final isValid = value == _newPasswordController.text;
    
    setState(() {
      _validations['confirmPassword'] = {
        'valid': isValid,
        'message': isValid 
            ? '비밀번호가 일치합니다.' 
            : '비밀번호가 일치하지 않습니다.',
      };
    });
  }

  // 비밀번호 변경 처리
  Future<void> _handleChangePassword() async {
    if (!_formKey.currentState!.validate() ||
        !_validations['newPassword']!['valid'] ||
        !_validations['confirmPassword']!['valid']) {
      
      setState(() {
        _errorMessage = '모든 필드를 올바르게 입력해주세요.';
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _successMessage = '';
    });
    
    try {
      final response = await _authService.changePassword(_newPasswordController.text);
      
      setState(() {
        _successMessage = response;
        // 폼 초기화
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        _validations = {
          'newPassword': {'valid': false, 'message': ''},
          'confirmPassword': {'valid': false, 'message': ''},
        };
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 비밀번호 요구사항 항목 위젯
  Widget _buildPasswordRequirement(String text, bool isMet) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.circle_outlined,
            color: isMet ? AppTheme.secondaryColor : AppTheme.textSecondaryColor,
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: AppTheme.bodySmall.copyWith(
              color: isMet ? AppTheme.secondaryColor : AppTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('비밀번호 변경'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: CardContainer(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.lock_outline,
                    size: 60,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '비밀번호 변경',
                    style: AppTheme.titleLarge.copyWith(
                      color: AppTheme.primaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '새 비밀번호를 입력해주세요.',
                    style: AppTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  
                  // 새 비밀번호
                  CommonTextField(
                    controller: _newPasswordController,
                    hintText: '새 비밀번호',
                    obscureText: true,
                    prefixIcon: const Icon(Icons.lock_outline),
                    onChanged: _validatePassword,
                    isValid: _newPasswordController.text.isNotEmpty ? _validations['newPassword']!['valid'] : null,
                    validationMessage: _newPasswordController.text.isNotEmpty ? _validations['newPassword']!['message'] : null,
                  ),
                  
                  // 비밀번호 요구사항
                  if (_newPasswordController.text.isNotEmpty)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildPasswordRequirement(
                            '8자 이상',
                            _validations['newPassword']!['isLongEnough'] ?? false,
                          ),
                          _buildPasswordRequirement(
                            '소문자 포함',
                            _validations['newPassword']!['hasLowerCase'] ?? false,
                          ),
                          _buildPasswordRequirement(
                            '대문자 포함',
                            _validations['newPassword']!['hasUpperCase'] ?? false,
                          ),
                          _buildPasswordRequirement(
                            '숫자 포함',
                            _validations['newPassword']!['hasNumber'] ?? false,
                          ),
                          _buildPasswordRequirement(
                            '특수문자 포함',
                            _validations['newPassword']!['hasSpecialChar'] ?? false,
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  
                  // 새 비밀번호 확인
                  CommonTextField(
                    controller: _confirmPasswordController,
                    hintText: '새 비밀번호 확인',
                    obscureText: true,
                    prefixIcon: const Icon(Icons.lock_outline),
                    onChanged: _validateConfirmPassword,
                    isValid: _confirmPasswordController.text.isNotEmpty
                        ? _validations['confirmPassword']!['valid']
                        : null,
                    validationMessage: _confirmPasswordController.text.isNotEmpty
                        ? _validations['confirmPassword']!['message']
                        : null,
                  ),
                  const SizedBox(height: 24),
                  
                  // 에러 메시지
                  if (_errorMessage.isNotEmpty)
                    ErrorMessageBox(message: _errorMessage),
                  
                  // 성공 메시지
                  if (_successMessage.isNotEmpty)
                    SuccessMessageBox(message: _successMessage),
                  
                  CommonButton(
                    text: '비밀번호 변경',
                    onPressed: _handleChangePassword,
                    isLoading: _isLoading,
                    isDisabled: !_validations['newPassword']!['valid'] ||
                        !_validations['confirmPassword']!['valid'],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      '취소',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}