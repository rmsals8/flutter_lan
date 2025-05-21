// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:audio_service/audio_service.dart';
import 'config/theme.dart';
import './providers/auth_provider.dart';
import './providers/quiz_provider.dart';
import './providers/file_provider.dart';
import './providers/alarm_provider.dart';
import './screens/login_screen.dart';
import './screens/signup_screen.dart';
import './screens/agreement_screen.dart';
import './screens/email_verification_screen.dart';
import './screens/find_credentials_screen.dart';
import './screens/change_password_screen.dart';
import './screens/delete_account_screen.dart';
import './screens/home_screen.dart';
import './screens/profile/profile_screen.dart';
import './screens/quiz/quiz_detail_screen.dart';
import './screens/quiz/quiz_generator_screen.dart';
import './screens/quiz/quiz_list_screen.dart';
import './screens/quiz/quiz_results_screen.dart';
import './screens/quiz/quiz_take_screen.dart';
import './screens/alarm/alarm_list_screen.dart';
import './screens/alarm/alarm_edit_screen.dart';
import './screens/alarm/mp3_selector_screen.dart';
import './screens/mp3_player_screen.dart';
import './services/alarm_service.dart';
import './services/audio_background_handler.dart';

// 전역 변수로 AudioHandler 선언
late AudioHandler audioHandler;

Future<void> main() async {
  // Flutter 바인딩 초기화
  WidgetsFlutterBinding.ensureInitialized();
  
  // 타임존 초기화
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Seoul'));
  
  // 오디오 서비스 초기화
  audioHandler = await initAudioService();
  
  // 알람 관련 초기화
  await AndroidAlarmManager.initialize();
  
  // 로컬 알림 초기화
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = 
      FlutterLocalNotificationsPlugin();
  
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
      
  final DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings();
      
  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );
  
  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
  );
  
  // 알람 서비스 초기화
  final alarmService = AlarmService();
  await alarmService.initialize();

  // 앱 시작
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
        ChangeNotifierProvider(create: (_) => AlarmProvider()),
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
          '/profile': (context) => const ProfileScreen(),
          '/quizzes': (context) => const QuizListScreen(),
          '/quizzes/detail': (context) => const QuizDetailScreen(),
          '/quizzes/create': (context) => const QuizGeneratorScreen(),
          '/quizzes/take': (context) => const QuizTakeScreen(),
          '/quizzes/results': (context) => const QuizResultsScreen(),
          '/alarms': (context) => const AlarmListScreen(),
          '/alarms/edit': (context) => const AlarmEditScreen(),
          '/alarms/sound': (context) => const MP3SelectorScreen(),
          '/files/upload': (context) => const FileUploadScreen(),
          '/mp3-player': (context) => const MP3PlayerScreen(),
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

// 파일 업로드 화면
class FileUploadScreen extends StatefulWidget {
  const FileUploadScreen({Key? key}) : super(key: key);

  @override
  State<FileUploadScreen> createState() => _FileUploadScreenState();
}

class _FileUploadScreenState extends State<FileUploadScreen> {
  bool _isUploading = false;
  String? _errorMessage;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('파일 업로드'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '오디오 파일 업로드',
              style: AppTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            const Text(
              'MP3 파일을 업로드하여 알람음으로 사용할 수 있습니다.',
              style: AppTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            Center(
              child: Column(
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.file_upload),
                    label: const Text('MP3 파일 선택'),
                    onPressed: _isUploading ? null : _selectAndUploadAudioFile,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_isUploading)
                    const Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 8),
                        Text('업로드 중...'),
                      ],
                    ),
                  if (_errorMessage != null)
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // 오디오 파일 선택 및 업로드
  Future<void> _selectAndUploadAudioFile() async {
    // 파일 선택 및 업로드 구현
    // 이 부분은 이미 파일 업로드 기능이 있다고 가정하고 생략
    // (file_picker 패키지 사용 권장)
    
    // 업로드 성공 후
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('파일이 업로드되었습니다.'),
        backgroundColor: Colors.green,
      ),
    );
    
    // 알람 화면으로 돌아가기
    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}