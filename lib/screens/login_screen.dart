import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../providers/auth_provider.dart';
import '../widgets/common_button.dart';
import '../widgets/common_text_field.dart';
import '../widgets/common_card.dart';
import '../config/theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _errorMessage = '';
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // 일반 로그인 처리
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (success && mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        setState(() {
          _errorMessage = authProvider.errorMessage;
        });
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

  // 구글 로그인 처리
  Future<void> _handleGoogleLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final GoogleSignInAccount? googleUser = await Provider.of<AuthProvider>(context, listen: false).startGoogleLogin();
      
      if (googleUser == null) {
        // 사용자가 로그인을 취소한 경우
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final googleAuth = await googleUser.authentication;
      final token = googleAuth.accessToken;

      if (token == null) {
        throw Exception('Google 인증에 실패했습니다.');
      }

      final response = await Provider.of<AuthProvider>(context, listen: false).googleLoginCheck(token);

      if (response.isRegistered && mounted) {
        // 이미 가입된 회원이면 홈 화면으로 이동
        Navigator.pushReplacementNamed(context, '/home');
      } else if (mounted) {
        // 가입되지 않은 회원이면 약관 동의 화면으로 이동
        Navigator.pushNamed(
          context, 
          '/agreements',
          arguments: {
            'googleToken': token,
            'email': response.email,
            'name': response.name,
            'googleId': response.googleId,
          },
        );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CardContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'LinguaEdge',
                      style: AppTheme.titleLarge.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          CommonTextField(
                            controller: _emailController,
                            hintText: '이메일',
                            keyboardType: TextInputType.emailAddress,
                            prefixIcon: const Icon(Icons.email_outlined),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return '이메일을 입력해주세요';
                              }
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                return '유효한 이메일 주소를 입력해주세요';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          CommonTextField(
                            controller: _passwordController,
                            hintText: '비밀번호',
                            obscureText: true,
                            prefixIcon: const Icon(Icons.lock_outline),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return '비밀번호를 입력해주세요';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          if (_errorMessage.isNotEmpty)
                            ErrorMessageBox(message: _errorMessage),
                          CommonButton(
                            text: '로그인',
                            onPressed: _handleLogin,
                            isLoading: _isLoading,
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: OrDivider(),
                    ),
                    GoogleSignInButton(
                      onPressed: _handleGoogleLogin,
                      isLoading: _isLoading,
                      text: '구글로 로그인',
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/find-credentials');
                          },
                          child: const Text('아이디/비밀번호 찾기'),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '계정이 없으신가요?',
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/signup');
                          },
                          child: const Text('회원가입'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}