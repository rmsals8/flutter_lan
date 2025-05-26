import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../widgets/common_button.dart';
import '../widgets/common_card.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({Key? key}) : super(key: key);

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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '회원가입 방법 선택',
                  style: AppTheme.titleLarge.copyWith(
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '원하시는 회원가입 방법을 선택해주세요.',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                CommonButton(
                  text: '이메일로 회원가입',
                  onPressed: () {
                    Navigator.pushNamed(context, '/agreements');
                  },
                ),
                const SizedBox(height: 16),
                GoogleSignInButton(
                  onPressed: () async {
                    // 구글 로그인 처리는 로그인 화면과 동일하게 구현
                    Navigator.pushNamed(context, '/login');
                  },
                  text: '구글로 회원가입',
                ),
                const SizedBox(height: 24),
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
    );
  }
}