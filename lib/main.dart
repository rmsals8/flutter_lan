// lib/main.dart

import 'dart:io';
import 'dart:convert'; // 추가
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:audio_service/audio_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 추가
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
import './screens/alarm/alarm_ringing_screen.dart'; // 새로 추가된 알람 화면
import './screens/mp3_player_screen.dart';
import './services/alarm_service.dart';
import './services/audio_background_handler.dart';
import './services/alarm_receiver.dart';
import './models/alarm.dart'; // Alarm 모델 import 추가

// 전역 변수로 AudioHandler 선언
late AudioHandler audioHandler;

// 전역 네비게이터 키 (알람 화면 표시용)
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// 다양한 알람 테스트 ID들
const int TEST_ALARM_ID_1 = 12345;
const int TEST_ALARM_ID_2 = 67890;

// main.dart에 추가
@pragma('vm:entry-point')
Future<void> alarmCallback(int id) async {
  debugPrint('====== 알람 콜백 실행 (main.dart): ID=$id, 시간=${DateTime.now()} ======');

  // 직접 AlarmReceiver의 onAlarm 메서드 호출
  await AlarmReceiver.onAlarm(id);
}

@pragma('vm:entry-point')
void _handleNotificationResponse(NotificationResponse response) {
  debugPrint('main.dart: 알림 응답 처리: ${response.payload}');

  // 알림을 탭했을 때 알람 화면으로 이동
  if (response.payload != null) {
    if (response.payload!.startsWith('alarm_wakeup_')) {
      // 앱 깨우기 알림을 탭한 경우
      final alarmIdStr = response.payload!.replaceFirst('alarm_wakeup_', '');

      try {
        final alarmId = int.parse(alarmIdStr);
        _showAlarmScreenFromNotification(alarmId);
      } catch (e) {
        debugPrint('알람 ID 파싱 오류: $e');
      }
    } else if (response.payload!.startsWith('alarm_')) {
      // 일반 알람 알림을 탭한 경우
      final alarmIdStr = response.payload!.replaceFirst('alarm_', '');

      try {
        final alarmId = int.parse(alarmIdStr);
        _showAlarmScreenFromNotification(alarmId);
      } catch (e) {
        debugPrint('알람 ID 파싱 오류: $e');
      }
    }
  }
}

// 알림에서 알람 화면을 표시하는 기능 - 개선된 버전
void _showAlarmScreenFromNotification(int alarmId) async {
  try {
    debugPrint('알림에서 알람 화면 표시: ID=$alarmId');

    // 앱이 실행 중이고 네비게이터가 준비되어 있다면
    if (navigatorKey.currentContext != null) {
      // SharedPreferences에서 실제 알람 데이터 가져오기
      try {
        final prefs = await SharedPreferences.getInstance();
        final alarmJson = prefs.getString('alarm_data_$alarmId');

        Alarm alarm;
        if (alarmJson != null) {
          final Map<String, dynamic> alarmMap = jsonDecode(alarmJson);
          alarm = Alarm(
            id: alarmMap['id'] ?? alarmId,
            time: TimeOfDay(
              hour: alarmMap['hour'] ?? TimeOfDay.now().hour,
              minute: alarmMap['minute'] ?? TimeOfDay.now().minute,
            ),
            repeatDays: List<bool>.from(alarmMap['repeatDays'] ?? List.filled(7, false)),
            label: alarmMap['label'] ?? '알람',
            soundPath: alarmMap['soundPath'] ?? 'assets/default_alarm.mp3',
            soundName: alarmMap['soundName'] ?? '기본 알람음',
          );
        } else {
          // 기본 알람 객체 생성
          alarm = Alarm(
            id: alarmId,
            time: TimeOfDay.now(),
            repeatDays: List.filled(7, false),
            label: '알람',
            soundPath: 'assets/default_alarm.mp3',
            soundName: '기본 알람음',
          );
        }

        // 알람 화면으로 이동
        navigatorKey.currentState?.pushNamedAndRemoveUntil(
          '/alarm-ringing',
              (route) => false, // 모든 이전 화면 제거
          arguments: {'alarm': alarm},
        );
      } catch (e) {
        debugPrint('알람 데이터 로드 오류: $e');

        // 오류 발생 시 기본 알람으로 표시
        final defaultAlarm = Alarm(
          id: alarmId,
          time: TimeOfDay.now(),
          repeatDays: List.filled(7, false),
          label: '알람',
          soundPath: 'assets/default_alarm.mp3',
          soundName: '기본 알람음',
        );

        navigatorKey.currentState?.pushNamedAndRemoveUntil(
          '/alarm-ringing',
              (route) => false,
          arguments: {'alarm': defaultAlarm},
        );
      }
    } else {
      debugPrint('네비게이터가 준비되지 않음');
    }
  } catch (e) {
    debugPrint('알림에서 알람 화면 표시 오류: $e');
  }
}

Future<void> main() async {
  // Flutter 바인딩 초기화
  WidgetsFlutterBinding.ensureInitialized();

  // 디버그 메시지
  debugPrint('앱 시작: ${DateTime.now().toString()}');

  // Android 12+ 에서 정확한 알람 권한 요청
  if (Platform.isAndroid) {
    try {
      // 필요한 권한 요청
      await _requestPermissions();
    } catch (e) {
      debugPrint('권한 요청 오류: $e');
    }
  }

  // 타임존 초기화
  try {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Seoul'));
    debugPrint('타임존 초기화 완료: ${tz.local.name}');
  } catch (e) {
    debugPrint('타임존 초기화 오류: $e');
  }

  // Android Alarm Manager 초기화
  try {
    final alarmManagerInitialized = await AndroidAlarmManager.initialize();
    debugPrint('AndroidAlarmManager 초기화: ${alarmManagerInitialized ? '성공' : '실패'}');
  } catch (e) {
    debugPrint('AndroidAlarmManager 초기화 오류: $e');
  }

  // 로컬 알림 초기화
  try {
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    // 수정된 iOS 초기화 설정 (onDidReceiveLocalNotification 제거)
    final DarwinInitializationSettings initializationSettingsIOS =
    DarwinInitializationSettings();

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _handleNotificationResponse,
    );

    // 알림 채널 생성
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'alarm_channel',
      '알람',
      description: '알람 알림 채널',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      enableLights: true,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    debugPrint('FlutterLocalNotifications 초기화 완료');
  } catch (e) {
    debugPrint('FlutterLocalNotifications 초기화 오류: $e');
  }

  // 오디오 서비스 초기화
  try {
    audioHandler = await initAudioService();
    debugPrint('AudioService 초기화 완료');
  } catch (e) {
    debugPrint('AudioService 초기화 오류: $e');
  }

  // 알람 서비스 초기화
  try {
    final alarmService = AlarmService();
    await alarmService.initialize();
    debugPrint('AlarmService 초기화 완료');
  } catch (e) {
    debugPrint('AlarmService 초기화 오류: $e');
  }

  // 앱 시작
  runApp(const MyApp());
}

// main.dart의 _requestPermissions 수정
Future<void> _requestPermissions() async {
  // 이 메서드는 매우 단순하게 유지
  if (Platform.isAndroid) {
    // 정확한 알람 권한 요청
    final status = await Permission.scheduleExactAlarm.status;
    if (!status.isGranted) {
      await Permission.scheduleExactAlarm.request();
      debugPrint('정확한 알람 권한 요청');
    } else {
      debugPrint('정확한 알람 권한 이미 있음');
    }

    // 알림 권한
    final notificationStatus = await Permission.notification.status;
    if (!notificationStatus.isGranted) {
      await Permission.notification.request();
      debugPrint('알림 권한 요청');
    } else {
      debugPrint('알림 권한 이미 있음');
    }
  }
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
        navigatorKey: navigatorKey, // 전역 네비게이터 키 설정
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
          '/alarm-ringing': (context) => _buildAlarmRingingScreen(context), // 새로 추가된 라우트
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

  // 알람이 울리는 화면을 만드는 기능
  Widget _buildAlarmRingingScreen(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (args != null && args.containsKey('alarm')) {
      final alarm = args['alarm'] as Alarm;
      return AlarmRingingScreen(alarm: alarm);
    } else {
      // 기본 알람 객체로 화면 생성
      final defaultAlarm = Alarm(
        id: 0,
        time: TimeOfDay.now(),
        repeatDays: List.filled(7, false),
        label: '알람',
        soundPath: 'assets/default_alarm.mp3',
        soundName: '기본 알람음',
      );
      return AlarmRingingScreen(alarm: defaultAlarm);
    }
  }
}

// 파일 업로드 화면 (간단히 유지)
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

  // 간단한 업로드 함수
  Future<void> _selectAndUploadAudioFile() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('파일이 업로드되었습니다.'),
        backgroundColor: Colors.green,
      ),
    );

    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}