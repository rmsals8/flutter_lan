import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:email_validator/email_validator.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../widgets/common_button.dart';
import '../widgets/common_text_field.dart';
import '../widgets/common_card.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  Map<String, dynamic>? _agreementData;
  String _errorMessage = '';
  bool _isLoading = false;
  
  // 유효성 검사 상태
  Map<String, Map<String, dynamic>> _validations = {
    'username': {'valid': false, 'message': ''},
    'email': {'valid': false, 'message': '', 'checked': false, 'checking': false},
    'password': {'valid': false, 'message': ''},
    'confirmPassword': {'valid': false, 'message': ''},
  };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // 라우트 파라미터에서 약관 동의 데이터 확인
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null && args is Map<String, dynamic>) {
      _agreementData = args['agreements'] as Map<String, dynamic>?;
    }
    
    // 약관 동의 데이터가 없으면 약관 동의 화면으로 이동
    if (_agreementData == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/agreements');
      });
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // 사용자명 유효성 검사
  void _validateUsername(String value) {
    final isValid = RegExp(r'^[a-zA-Z0-9가-힣]{3,20}$').hasMatch(value);
    
    setState(() {
      _validations['username'] = {
        'valid': isValid,
        'message': isValid 
            ? '사용 가능한 사용자명입니다.' 
            : '사용자명은 3-20자의 영문자, 숫자, 한글만 포함할 수 있습니다.',
      };
    });
  }

  // 이메일 유효성 검사
  void _validateEmail(String value) {
    final isValid = EmailValidator.validate(value);
    
    setState(() {
      _validations['email'] = {
        'valid': isValid,
        'message': isValid 
            ? '중복 확인이 필요합니다.' 
            : '유효한 이메일 주소를 입력해주세요.',
        'checked': false,
        'checking': false,
      };
    });
  }

  // 이메일 중복 확인
  Future<void> _checkEmailAvailability() async {
    if (!_validations['email']!['valid'] || _validations['email']!['checking']) {
      return;
    }
    
    setState(() {
      _validations['email'] = {
        ..._validations['email']!,
        'checking': true,
      };
    });
    
    try {
      final isAvailable = await Provider.of<AuthProvider>(context, listen: false)
          .checkEmailAvailability(_emailController.text.trim());
      
      setState(() {
        _validations['email'] = {
          'valid': isAvailable,
          'message': isAvailable 
              ? '사용 가능한 이메일입니다.' 
              : '이미 사용 중인 이메일입니다.',
          'checked': true,
          'checking': false,
        };
      });
    } catch (e) {
      setState(() {
        _validations['email'] = {
          'valid': false,
          'message': '이메일 확인 중 오류가 발생했습니다.',
          'checked': false,
          'checking': false,
        };
      });
    }
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
      _validations['password'] = {
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
    final isValid = value == _passwordController.text;
    
    setState(() {
      _validations['confirmPassword'] = {
        'valid': isValid,
        'message': isValid 
            ? '비밀번호가 일치합니다.' 
            : '비밀번호가 일치하지 않습니다.',
      };
    });
  }

  // 회원가입 처리
  Future<void> _handleRegister() async {
    // 필드 검증
    if (!_formKey.currentState!.validate() ||
        !_validations['username']!['valid'] ||
        !_validations['email']!['valid'] ||
        !_validations['email']!['checked'] ||
        !_validations['password']!['valid'] ||
        !_validations['confirmPassword']!['valid']) {
      
      setState(() {
        _errorMessage = '모든 필드를 올바르게 입력해주세요.';
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      final registerData = {
        'username': _usernameController.text.trim(),
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
      };
      
      final response = await Provider.of<AuthProvider>(context, listen: false)
          .register(registerData, _agreementData!);
      
      if (mounted) {
        // 이메일 인증 화면으로 이동
        if (response['verificationToken'] != null) {
          Navigator.pushReplacementNamed(
            context,
            '/verify-email',
            arguments: {
              'email': _emailController.text.trim(),
              'verificationToken': response['verificationToken'],
            },
          );
        } else {
          Navigator.pushReplacementNamed(
            context,
            '/verify-email',
            arguments: {
              'email': _emailController.text.trim(),
            },
          );
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
        title: const Text('회원가입'),
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
                  Text(
                    '계정 정보 입력',
                    style: AppTheme.titleLarge.copyWith(
                      color: AppTheme.primaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  
                  // 사용자명
                  CommonTextField(
                    controller: _usernameController,
                    hintText: '사용자명 (3-20자)',
                    prefixIcon: const Icon(Icons.person_outline),
                    onChanged: _validateUsername,
                    isValid: _usernameController.text.isNotEmpty ? _validations['username']!['valid'] : null,
                    validationMessage: _usernameController.text.isNotEmpty ? _validations['username']!['message'] : null,
                  ),
                  const SizedBox(height: 16),
                  
                  // 이메일
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: CommonTextField(
                          controller: _emailController,
                          hintText: '이메일',
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: const Icon(Icons.email_outlined),
                          onChanged: _validateEmail,
                          isValid: _emailController.text.isNotEmpty
                              ? (_validations['email']!['checked']
                                  ? _validations['email']!['valid']
                                  : null)
                              : null,
                          validationMessage: _emailController.text.isNotEmpty
                              ? _validations['email']!['message']
                              : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _validations['email']!['valid'] &&
                                    !_validations['email']!['checked'] &&
                                    !_validations['email']!['checking']
                                ? _checkEmailAvailability
                                : null,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              backgroundColor: _validations['email']!['checked'] &&
                                      _validations['email']!['valid']
                                  ? AppTheme.secondaryColor
                                  : null,
                            ),
                            child: _validations['email']!['checking']
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Text(
                                    _validations['email']!['checked'] && _validations['email']!['valid']
                                        ? '확인됨'
                                        : '중복확인',
                                    style: AppTheme.bodyMedium.copyWith(
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // 비밀번호
                  CommonTextField(
                    controller: _passwordController,
                    hintText: '비밀번호',
                    obscureText: true,
                    prefixIcon: const Icon(Icons.lock_outline),
                    onChanged: _validatePassword,
                    isValid: _passwordController.text.isNotEmpty ? _validations['password']!['valid'] : null,
                    validationMessage: _passwordController.text.isNotEmpty ? _validations['password']!['message'] : null,
                  ),
                  
                  // 비밀번호 요구사항
                  if (_passwordController.text.isNotEmpty)
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
                            _validations['password']!['isLongEnough'] ?? false,
                          ),
                          _buildPasswordRequirement(
                            '소문자 포함',
                            _validations['password']!['hasLowerCase'] ?? false,
                          ),
                          _buildPasswordRequirement(
                            '대문자 포함',
                            _validations['password']!['hasUpperCase'] ?? false,
                          ),
                          _buildPasswordRequirement(
                            '숫자 포함',
                            _validations['password']!['hasNumber'] ?? false,
                          ),
                          _buildPasswordRequirement(
                            '특수문자 포함',
                            _validations['password']!['hasSpecialChar'] ?? false,
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  
                  // 비밀번호 확인
                  CommonTextField(
                    controller: _confirmPasswordController,
                    hintText: '비밀번호 확인',
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
                  
                  if (_errorMessage.isNotEmpty)
                    ErrorMessageBox(message: _errorMessage),
                  
                  CommonButton(
                    text: '회원가입',
                    onPressed: _handleRegister,
                    isLoading: _isLoading,
                    isDisabled: !_validations['username']!['valid'] ||
                        !_validations['email']!['valid'] ||
                        !_validations['email']!['checked'] ||
                        !_validations['password']!['valid'] ||
                        !_validations['confirmPassword']!['valid'],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '이미 계정이 있으신가요?',
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, '/login');
                        },
                        child: const Text('로그인'),
                      ),
                    ],
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