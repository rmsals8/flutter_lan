import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/theme.dart';
import '../services/auth_service.dart';
import '../widgets/common_button.dart';
import '../widgets/common_card.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({Key? key}) : super(key: key);

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final TextEditingController _verificationCodeController = TextEditingController();
  final AuthService _authService = AuthService();
  
  String _email = '';
  String? _verificationToken;
  String _message = '';
  bool _isLoading = false;
  bool _isSuccess = false;
  int? _countdown;
  int _cooldown = 0;
  bool _isResending = false;
  Timer? _cooldownTimer;
  Timer? _countdownTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // 라우트 파라미터에서 이메일과 인증 토큰 확인
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null && args is Map<String, dynamic>) {
      final email = args['email'] as String?;
      final token = args['verificationToken'] as String?;
      
      if (email != null && email.isNotEmpty) {
        _email = email;
        _message = '$_email 주소로 발송된 인증번호를 입력해주세요.';
        
        if (token != null && token.isNotEmpty) {
          _verificationToken = token;
          
          // 인증 코드 요청
          _fetchVerificationCode();
        }
      } else {
        _message = '유효하지 않은 접근입니다. 회원가입을 다시 진행해주세요.';
      }
    }
  }

  @override
  void dispose() {
    _verificationCodeController.dispose();
    _cooldownTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  // 인증 코드 요청
  Future<void> _fetchVerificationCode() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final message = await _authService.getVerificationCode(_verificationToken!);
      setState(() {
        _message = message;
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

  // 이메일 인증 처리
  Future<void> _handleVerifyEmail() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final message = await _authService.verifyEmail(_email, _verificationCodeController.text);
      
      setState(() {
        _message = message;
        _isSuccess = true;
        _countdown = 3; // 3초 카운트다운 시작
      });
      
      _startCountdownForRedirect();
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

  // 인증번호 재발송
  Future<void> _handleResendVerification() async {
    if (_cooldown > 0 || _isResending || _email.isEmpty) {
      return;
    }
    
    setState(() {
      _isResending = true;
    });
    
    try {
      final message = await _authService.resendVerification(_email);
      
      setState(() {
        _message = message;
        _cooldown = 60; // 60초 쿨다운 시작
      });
      
      _startCooldownTimer();
    } catch (e) {
      setState(() {
        _message = e.toString();
      });
    } finally {
      setState(() {
        _isResending = false;
      });
    }
  }

  // 쿨다운 타이머 시작
  void _startCooldownTimer() {
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_cooldown <= 1) {
          _cooldown = 0;
          timer.cancel();
        } else {
          _cooldown--;
        }
      });
    });
  }

  // 리다이렉트용 카운트다운 타이머 시작
  void _startCountdownForRedirect() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_countdown! <= 1) {
          _countdown = 0;
          timer.cancel();
          Navigator.pushReplacementNamed(context, '/login');
        } else {
          _countdown = _countdown! - 1;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: _isSuccess 
          ? null // 성공 화면에서는 앱바 숨김
          : AppBar(
              title: const Text('이메일 인증'),
              automaticallyImplyLeading: false, // 뒤로가기 버튼 숨김
            ),
      body: Center(
        child: SingleChildScrollView(
          child: CardContainer(
            child: _isSuccess 
                ? _buildSuccessContent() 
                : _buildVerificationContent(),
          ),
        ),
      ),
    );
  }

  // 인증 화면 위젯
  Widget _buildVerificationContent() {
    return Column(
      children: [
        const Icon(
          Icons.email_outlined,
          size: 60,
          color: AppTheme.primaryColor,
        ),
        const SizedBox(height: 16),
        Text(
          '이메일 인증',
          style: AppTheme.titleLarge.copyWith(
            color: AppTheme.primaryColor,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          _message,
          style: AppTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        if (_email.isNotEmpty) ...[
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
            style: AppTheme.bodyLarge.copyWith(
            letterSpacing: 8,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            ),
            ),
          ),
          const SizedBox(height: 24),
          
          // 인증하기 버튼
          CommonButton(
            text: '인증하기',
            onPressed: _handleVerifyEmail,
            isLoading: _isLoading,
            isDisabled: _verificationCodeController.text.length != 6,
          ),
          
          const SizedBox(height: 16),
          
          // 인증번호 재발송 영역
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              children: [
                Text(
                  '인증번호를 받지 못하셨나요?',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _cooldown > 0 || _isResending ? null : _handleResendVerification,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  child: Text(
                    _cooldown > 0 
                        ? '재발송 (${_cooldown}초 후 가능)' 
                        : (_isResending ? '발송 중...' : '인증번호 재발송'),
                    style: AppTheme.bodyMedium.copyWith(
                      color: _cooldown > 0 || _isResending 
                          ? AppTheme.textSecondaryColor 
                          : AppTheme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // 인증 성공 화면 위젯
  Widget _buildSuccessContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.check_circle_outline,
          size: 80,
          color: AppTheme.secondaryColor,
        ),
        const SizedBox(height: 24),
        Text(
          '인증 완료!',
          style: AppTheme.titleLarge.copyWith(
            color: AppTheme.secondaryColor,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          _message,
          style: AppTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Text(
          '${_countdown}초 후 로그인 페이지로 이동합니다...',
          style: AppTheme.bodyLarge.copyWith(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}