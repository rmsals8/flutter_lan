import 'package:flutter/material.dart';
import 'package:lingedge1/screens/profile/profile_screen.dart';
import 'package:lingedge1/screens/quiz/quiz_detail_screen.dart';
import 'package:lingedge1/screens/quiz/quiz_generator_screen.dart';
import 'package:lingedge1/screens/quiz/quiz_list_screen.dart';
import 'package:lingedge1/screens/quiz/quiz_results_screen.dart';
import 'package:lingedge1/screens/quiz/quiz_take_screen.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/quiz_provider.dart'; // 추가
import 'providers/file_provider.dart'; // 추가
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/agreement_screen.dart';
import 'screens/email_verification_screen.dart';
import 'screens/find_credentials_screen.dart';
import 'screens/change_password_screen.dart';
import 'screens/delete_account_screen.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => QuizProvider()),
        ChangeNotifierProvider(create: (_) => FileProvider()),
      ],
      child: MaterialApp(
        title: 'LinguaEdge',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('ko', ''),
          Locale('en', ''),
        ],
        locale: const Locale('ko'),
        initialRoute: '/',
        routes: {
          '/': (context) => _determineHomeScreen(context),
          '/login': (context) => const LoginScreen(),
          '/signup': (context) => const SignupScreen(),
          '/agreements': (context) => const AgreementScreen(),
          '/verify-email': (context) => const EmailVerificationScreen(),
          '/find-credentials': (context) => const FindCredentialsScreen(),
          '/change-password': (context) => const ChangePasswordScreen(),
          '/delete-account': (context) => const DeleteAccountScreen(),
          '/home': (context) => const HomeScreen(),
          // 추가한 라우트들
          '/profile': (context) => const ProfileScreen(),
          '/quizzes': (context) => const QuizListScreen(),
          '/quizzes/detail': (context) => const QuizDetailScreen(),
          '/quizzes/create': (context) => const QuizGeneratorScreen(),
          '/quizzes/take': (context) => const QuizTakeScreen(),
          '/quizzes/results': (context) => const QuizResultsScreen(),
        },
      ),
    );
  }

  Widget _determineHomeScreen(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    // 초기 화면 결정 로직
    if (authProvider.isAuthenticated) {
      return const HomeScreen();
    } else {
      return const LoginScreen();
    }
  }
}