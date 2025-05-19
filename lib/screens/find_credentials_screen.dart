import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/theme.dart';
import '../services/auth_service.dart';
import '../widgets/common_button.dart';
import '../widgets/common_text_field.dart';
import '../widgets/common_card.dart';

class FindCredentialsScreen extends StatefulWidget {
  const FindCredentialsScreen({Key? key}) : super(key: key);

  @override
  State<FindCredentialsScreen> createState() => _FindCredentialsScreenState();
}

class _FindCredentialsScreenState extends State<FindCredentialsScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _verificationCodeController = TextEditingController();
  final AuthService _authService = AuthService();
  
  int _step = 1; // 1: 이메일 입력, 2: 인증번호 입력, 3: 결과 표시
  String _actionType = 'password'; // 'username' 또는 'password'
  String _message = '';
  String _username = '';
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _verificationCodeController.dispose();
    super.dispose();
  }

  // 인증번호 발송
  Future<void> _handleSendVerificationCode() async {
    if (_emailController.text.isEmpty) {
      setState(() {
        _message = '이메일을 입력해주세요.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _message = '';
    });
    
    try {
      final response = await _authService.sendVerificationForCredential(_emailController.text);
      
      setState(() {
        _message = response;
        _step = 2; // 인증코드 입력 단계로 이동
      });
    } catch (e) {
      setState(() {
        _message = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 아이디 찾기 처리
  Future<void> _handleVerifyForUsername() async {
    setState(() {
      _isLoading = true;
      _message = '';
    });
    
    try {
      final response = await _authService.findUsername(
        _emailController.text,
        _verificationCodeController.text,
      );
      
      setState(() {
        _username = response['username'] ?? '';
        _message = '회원님의 아이디는 $_username 입니다.';
        _step = 3; // 결과 표시 단계로 이동
      });
    } catch (e) {
      setState(() {
        _message = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 비밀번호 재설정 처리
  Future<void> _handleVerifyForPasswordReset() async {
    setState(() {
      _isLoading = true;
      _message = '';
    });
    
    try {
      final response = await _authService.resetPassword(
        _emailController.text,
        _verificationCodeController.text,
      );
      
      setState(() {
        _message = response;
        _step = 3; // 결과 표시 단계로 이동
      });
    } catch (e) {
      setState(() {
        _message = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(_step == 1 
            ? '계정 찾기' 
            : (_step == 2 
                ? (_actionType == 'username' ? '아이디 찾기' : '비밀번호 재설정') 
                : (_actionType == 'username' ? '아이디 찾기 결과' : '비밀번호 재설정 결과'))),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_step == 1) {
              Navigator.pop(context);
            } else {
              setState(() {
                _step = 1;
                _message = '';
                _verificationCodeController.clear();
              });
            }
          },
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: CardContainer(
            child: _step == 1 
                ? _buildStep1() 
                : (_step == 2 
                    ? _buildStep2() 
                    : _buildStep3()),
          ),
        ),
      ),
    );
  }

  // 단계 1: 이메일 입력
  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Icon(
          Icons.lock_reset,
          size: 60,
          color: AppTheme.primaryColor,
        ),
        const SizedBox(height: 16),
        Text(
          '계정 찾기',
          style: AppTheme.titleLarge.copyWith(
            color: AppTheme.primaryColor,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        const Text(
          '가입 시 사용한 이메일 주소를 입력하시면 인증번호를 발송해 드립니다.',
          style: AppTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        CommonTextField(
          controller: _emailController,
          hintText: '이메일',
          keyboardType: TextInputType.emailAddress,
          prefixIcon: const Icon(Icons.email_outlined),
        ),
        if (_message.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              _message,
              style: AppTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
        ],
        const SizedBox(height: 24),
        // 잠시 비밀번호 재설정만 작업
        CommonButton(
          text: '비밀번호 재설정',
          onPressed: () {
            _actionType = 'password';
            _handleSendVerificationCode();
          },
          isLoading: _isLoading,
          backgroundColor: AppTheme.primaryColor,
        ),
        /* 
        // 아이디 찾기 기능 추가 (필요한 경우 주석 해제)
        CommonButton(
          text: '아이디 찾기',
          onPressed: () {
            _actionType = 'username';
            _handleSendVerificationCode();
          },
          isLoading: _isLoading,
          backgroundColor: AppTheme.secondaryColor,
        ),
        */
      ],
    );
  }

  // 단계 2: 인증번호 입력
  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Icon(
          Icons.email_outlined,
          size: 60,
          color: AppTheme.primaryColor,
        ),
        const SizedBox(height: 16),
        Text(
          _actionType == 'username' ? '아이디 찾기' : '비밀번호 재설정',
          style: AppTheme.titleLarge.copyWith(
            color: AppTheme.primaryColor,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            text: '인증번호가 ',
            style: AppTheme.bodyMedium,
            children: [
              TextSpan(
                text: _emailController.text,
                style: AppTheme.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const TextSpan(
                text: '로 발송되었습니다.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '이메일을 확인하고 인증번호를 입력해주세요.',
          style: AppTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        // 인증번호 입력 필드
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: TextField(
            controller: _verificationCodeController,
            decoration: InputDecoration(
              hintText: '인증번호 6자리 입력',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            style: AppTheme.titleMedium.copyWith(
              letterSpacing: 8,
            ),
          ),
        ),
        if (_message.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              _message,
              style: AppTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
        ],
        const SizedBox(height: 24),
        CommonButton(
          text: '인증하기',
          onPressed: _actionType == 'username' ? _handleVerifyForUsername : _handleVerifyForPasswordReset,
          isLoading: _isLoading,
          isDisabled: _verificationCodeController.text.length != 6,
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () {
            setState(() {
              _step = 1;
              _verificationCodeController.clear();
            });
          },
          child: Text(
            '뒤로 가기',
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ),
      ],
    );
  }

  // 단계 3: 결과 표시
  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          _actionType == 'username' ? Icons.person_outline : Icons.lock_open,
          size: 60,
          color: AppTheme.primaryColor,
        ),
        const SizedBox(height: 16),
        Text(
          _actionType == 'username' ? '아이디 찾기 결과' : '비밀번호 재설정 완료',
          style: AppTheme.titleLarge.copyWith(
            color: AppTheme.primaryColor,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: AppTheme.backgroundColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.dividerColor),
          ),
          child: Column(
            children: [
              if (_actionType == 'username' && _username.isNotEmpty) ...[
                const Text(
                  '회원님의 아이디는',
                  style: AppTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _username,
                  style: AppTheme.titleLarge.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  '입니다.',
                  style: AppTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ] else ...[
                Text(
                  _message,
                  style: AppTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
        CommonButton(
          text: '로그인하기',
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/login');
          },
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () {
            setState(() {
              _step = 1;
              _emailController.clear();
              _verificationCodeController.clear();
              _message = '';
              _username = '';
            });
          },
          child: Text(
            '다시 찾기',
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ),
      ],
    );
  }
}