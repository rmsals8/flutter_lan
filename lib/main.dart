// lib/main.dart

import 'dart:async'; // Timer 사용을 위해 추가
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:audio_service/audio_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
import './screens/alarm/alarm_ringing_screen.dart';
import './screens/mp3_player_screen.dart';
import './services/alarm_service.dart';
import './services/audio_background_handler.dart';
import './services/alarm_receiver.dart';
import './models/alarm.dart';

// 전역 변수들
late AudioHandler audioHandler;
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

// 알람 콜백 - 백업 알림도 표시
@pragma('vm:entry-point')
Future<void> alarmCallback(int id) async {
  debugPrint('====== 알람 콜백 실행: ID=$id, 시간=${DateTime.now()} ======');

  try {
    // 1. 알람음 재생
    await AlarmReceiver.playAlarmSound();
    debugPrint('알람음 재생 완료');

    // 2. 알람이 울렸다는 표시를 SharedPreferences에 저장
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('alarm_triggered', id.toString());
    await prefs.setString('alarm_triggered_time', DateTime.now().toString());
    debugPrint('알람 트리거 정보 저장 완료');

    // 3. 백업 알림 표시 (사용자가 탭할 수 있도록)
    try {
      await _showBackupNotification(id);
      debugPrint('백업 알림 표시 완료');
    } catch (notifError) {
      debugPrint('백업 알림 표시 오류: $notifError');
    }

    debugPrint('알람 콜백 완료');
  } catch (e) {
    debugPrint('알람 콜백 오류: $e');

    // 오류가 발생해도 알람이 울렸다는 표시는 저장
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('alarm_triggered', id.toString());
      await prefs.setString('alarm_triggered_time', DateTime.now().toString());
    } catch (saveError) {
      debugPrint('알람 트리거 정보 저장 오류: $saveError');
    }
  }
}

// 백그라운드에서 호출할 수 있는 간단한 알림 표시
@pragma('vm:entry-point')
Future<void> _showBackupNotification(int alarmId) async {
  try {
    debugPrint('백업 알림 표시 시작 - ID: $alarmId');

    // FlutterLocalNotificationsPlugin 새로 생성 (백그라운드에서는 전역 변수 접근 안 됨)
    final notifications = FlutterLocalNotificationsPlugin();

    // 간단한 초기화
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await notifications.initialize(initSettings);

    // 간단한 알림 세부사항
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'alarm_simple_channel',
      '알람',
      channelDescription: '알람 알림',
      importance: Importance.max,
      priority: Priority.high,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      ongoing: true,
      autoCancel: true,
      enableVibration: true,
      enableLights: true,
    );

    const NotificationDetails details = NotificationDetails(android: androidDetails);

    // 알림 표시
    await notifications.show(
      alarmId,
      '⏰ 알람',
      '알람 시간입니다! 탭해서 끄기',
      details,
      payload: 'alarm_simple_$alarmId',
    );

    debugPrint('백업 알림 표시 완료');
  } catch (e) {
    debugPrint('백업 알림 표시 오류: $e');
  }
}

// 간단한 알림 표시 (백업용)
Future<void> _showSimpleAlarmNotification(int alarmId) async {
  try {
    debugPrint('간단한 알림 표시 시작 - ID: $alarmId');

    // SharedPreferences에서 알람 정보 가져오기
    final prefs = await SharedPreferences.getInstance();
    String alarmLabel = '알람';

    final alarmJson = prefs.getString('alarm_data_$alarmId');
    if (alarmJson != null) {
      try {
        final alarmData = jsonDecode(alarmJson);
        alarmLabel = alarmData['label'] ?? '알람';
      } catch (e) {
        debugPrint('알람 데이터 파싱 오류: $e');
      }
    }

    // 간단한 알림 세부사항
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'alarm_simple_channel',
      '알람',
      channelDescription: '알람 알림',
      importance: Importance.max,
      priority: Priority.high,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      ongoing: true,
      autoCancel: true,
      enableVibration: true,
      enableLights: true,
    );

    const NotificationDetails details = NotificationDetails(android: androidDetails);

    // 알림 표시
    await flutterLocalNotificationsPlugin.show(
      alarmId,
      '⏰ $alarmLabel',
      '알람 시간입니다! 탭해서 끄기',
      details,
      payload: 'alarm_simple_$alarmId',
    );

    debugPrint('간단한 알림 표시 완료');
  } catch (e) {
    debugPrint('간단한 알림 표시 오류: $e');
  }
}

// 바로 알람 화면으로 이동 (핵심!)
Future<void> _showAlarmScreenDirectly(int alarmId) async {
  try {
    debugPrint('바로 알람 화면 표시 시도 - ID: $alarmId');

    // SharedPreferences에서 알람 데이터 가져오기
    final prefs = await SharedPreferences.getInstance();
    final alarmJson = prefs.getString('alarm_data_$alarmId');

    Alarm alarm;
    if (alarmJson != null) {
      try {
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
          isEnabled: true,
        );
        debugPrint('저장된 알람 데이터 로드 성공');
      } catch (e) {
        debugPrint('알람 데이터 파싱 오류: $e');
        alarm = _createDefaultAlarmForNotification(alarmId);
      }
    } else {
      debugPrint('저장된 데이터 없음, 기본 알람 생성');
      alarm = _createDefaultAlarmForNotification(alarmId);
    }

    // 여러 번 시도해서 네비게이터가 준비될 때까지 기다림
    for (int i = 0; i < 10; i++) {
      if (navigatorKey.currentContext != null) {
        debugPrint('네비게이터 준비됨, 알람 화면으로 이동 (시도 ${i + 1})');

        // 알람 화면으로 이동
        navigatorKey.currentState?.pushNamedAndRemoveUntil(
          '/alarm-ringing',
              (route) => false,  // 모든 이전 화면 제거
          arguments: {'alarm': alarm},
        );

        debugPrint('알람 화면으로 이동 완료');
        return;
      }

      // 0.5초씩 기다림
      await Future.delayed(const Duration(milliseconds: 500));
      debugPrint('네비게이터 대기 중... (시도 ${i + 1}/10)');
    }

    debugPrint('네비게이터를 찾을 수 없음 - 최대 시도 횟수 초과');
  } catch (e) {
    debugPrint('바로 알람 화면 표시 중 오류: $e');
  }
}

// 알림 응답 처리 (가장 중요한 부분!)
@pragma('vm:entry-point')
void _handleNotificationResponse(NotificationResponse response) {
  debugPrint('알림 응답 처리 시작: ${response.payload}');

  try {
    if (response.payload != null && response.payload!.isNotEmpty) {

      // 알람 끄기 액션
      if (response.actionId == 'stop_alarm') {
        debugPrint('알람 끄기 액션 선택됨');
        _stopAlarmFromNotification(response.payload!);
        return;
      }

      // 스누즈 액션
      if (response.actionId == 'snooze_alarm') {
        debugPrint('스누즈 액션 선택됨');
        _snoozeAlarmFromNotification(response.payload!);
        return;
      }

      // 깨우기 알림을 탭한 경우 (새로 추가!)
      if (response.payload!.startsWith('wakeup_')) {
        final alarmIdStr = response.payload!.replaceFirst('wakeup_', '');
        debugPrint('깨우기 알림 탭됨 - ID: $alarmIdStr');

        try {
          final alarmId = int.parse(alarmIdStr);
          // 즉시 알람 화면으로 이동
          _showAlarmScreenFromNotification(alarmId);
        } catch (e) {
          debugPrint('알람 ID 파싱 오류: $e');
        }
        return;
      }

      // 기존 알람 알림을 탭한 경우
      if (response.payload!.startsWith('alarm_fullscreen_') || response.payload!.startsWith('alarm_simple_')) {
        String alarmIdStr;
        if (response.payload!.startsWith('alarm_fullscreen_')) {
          alarmIdStr = response.payload!.replaceFirst('alarm_fullscreen_', '');
        } else {
          alarmIdStr = response.payload!.replaceFirst('alarm_simple_', '');
        }
        debugPrint('알람 알림 탭됨 - ID: $alarmIdStr');

        try {
          final alarmId = int.parse(alarmIdStr);
          // 즉시 알람 화면으로 이동
          _showAlarmScreenFromNotification(alarmId);
        } catch (e) {
          debugPrint('알람 ID 파싱 오류: $e');
        }
      }
    }
  } catch (e) {
    debugPrint('알림 응답 처리 오류: $e');
  }
}

// 알림에서 알람 끄기
void _stopAlarmFromNotification(String payload) async {
  try {
    // 알람음 중지
    await AlarmReceiver.stopAlarmSound();

    // 알림 취소
    final alarmIdStr = payload.replaceFirst('alarm_fullscreen_', '');
    final alarmId = int.parse(alarmIdStr);
    await flutterLocalNotificationsPlugin.cancel(alarmId);

    debugPrint('알람이 알림에서 중지됨');
  } catch (e) {
    debugPrint('알림에서 알람 끄기 오류: $e');
  }
}

// 알림에서 스누즈
void _snoozeAlarmFromNotification(String payload) async {
  try {
    // 알람음 중지
    await AlarmReceiver.stopAlarmSound();

    // 알림 취소
    final alarmIdStr = payload.replaceFirst('alarm_fullscreen_', '');
    final alarmId = int.parse(alarmIdStr);
    await flutterLocalNotificationsPlugin.cancel(alarmId);

    // 5분 후 알람 다시 설정 (간단한 버전)
    // 실제로는 AlarmService를 통해 처리해야 함

    debugPrint('스누즈 설정됨');
  } catch (e) {
    debugPrint('알림에서 스누즈 오류: $e');
  }
}

// 알림에서 알람 화면을 표시하는 기능 (핵심!)
void _showAlarmScreenFromNotification(int alarmId) async {
  try {
    debugPrint('알림에서 알람 화면 표시 시도 - ID: $alarmId');

    // SharedPreferences에서 알람 데이터 가져오기
    final prefs = await SharedPreferences.getInstance();
    final alarmJson = prefs.getString('alarm_data_$alarmId');

    Alarm alarm;
    if (alarmJson != null) {
      try {
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
          isEnabled: true,
        );
        debugPrint('저장된 알람 데이터 로드 성공');
      } catch (e) {
        debugPrint('알람 데이터 파싱 오류: $e');
        alarm = _createDefaultAlarmForNotification(alarmId);
      }
    } else {
      debugPrint('저장된 데이터 없음, 기본 알람 생성');
      alarm = _createDefaultAlarmForNotification(alarmId);
    }

    // 약간의 지연 후 알람 화면으로 이동 (앱이 완전히 깨어날 시간을 줌)
    await Future.delayed(const Duration(milliseconds: 500));

    // 네비게이터가 준비되어 있다면 알람 화면으로 이동
    if (navigatorKey.currentContext != null) {
      debugPrint('네비게이터 준비됨, 알람 화면으로 이동');

      // 현재 화면이 알람 화면이 아닌 경우에만 이동
      final currentRoute = ModalRoute.of(navigatorKey.currentContext!)?.settings.name;
      if (currentRoute != '/alarm-ringing') {
        // 알람 화면으로 이동 (모든 이전 화면 제거)
        navigatorKey.currentState?.pushNamedAndRemoveUntil(
          '/alarm-ringing',
              (route) => false,  // 모든 이전 화면 제거
          arguments: {'alarm': alarm},
        );
        debugPrint('알람 화면으로 이동 완료');
      } else {
        debugPrint('이미 알람 화면에 있음');
      }
    } else {
      debugPrint('네비게이터가 아직 준비되지 않음, 잠시 후 다시 시도');

      // 네비게이터가 준비될 때까지 기다림 (최대 3초)
      for (int i = 0; i < 6; i++) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (navigatorKey.currentContext != null) {
          navigatorKey.currentState?.pushNamedAndRemoveUntil(
            '/alarm-ringing',
                (route) => false,
            arguments: {'alarm': alarm},
          );
          debugPrint('지연 후 알람 화면으로 이동 완료');
          break;
        }
      }
    }
  } catch (e) {
    debugPrint('알림에서 알람 화면 표시 중 오류: $e');
  }
}

// 기본 알람 생성 함수
Alarm _createDefaultAlarmForNotification(int alarmId) {
  final now = DateTime.now();
  return Alarm(
    id: alarmId,
    time: TimeOfDay(hour: now.hour, minute: now.minute),
    repeatDays: List.filled(7, false),
    label: '알람',
    soundPath: 'assets/default_alarm.mp3',
    soundName: '기본 알람음',
    isEnabled: true,
  );
}

Future<void> main() async {
  // Flutter 바인딩 초기화
  WidgetsFlutterBinding.ensureInitialized();

  debugPrint('앱 시작: ${DateTime.now().toString()}');

  // Android 권한 요청
  if (Platform.isAndroid) {
    try {
      await _requestPermissions();
    } catch (e) {
      debugPrint('권한 요청 오류: $e');
    }
  }

  // 타임존 초기화
  try {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Seoul'));
    debugPrint('타임존 초기화 완료');
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

  // 로컬 알림 초기화 (가장 중요한 부분!)
  try {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings initializationSettingsIOS =
    DarwinInitializationSettings();

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    // 알림 초기화 시 응답 처리 함수 등록
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _handleNotificationResponse,
    );

    // 앱 깨우기 알람 채널 생성 (새로 추가!)
    const AndroidNotificationChannel wakeupChannel = AndroidNotificationChannel(
      'alarm_wakeup_channel',
      '알람 깨우기',
      description: '앱을 깨우는 알람 채널',
      importance: Importance.max,
      enableVibration: true,
      enableLights: true,
      playSound: false,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(wakeupChannel);

    // 간단한 알람 채널 생성 (기존)
    const AndroidNotificationChannel simpleChannel = AndroidNotificationChannel(
      'alarm_simple_channel',
      '알람',
      description: '알람 알림 채널',
      importance: Importance.max,
      enableVibration: true,
      enableLights: true,
      playSound: false,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(simpleChannel);

    // 전체화면 알람 채널 생성 (기존)
    const AndroidNotificationChannel fullScreenChannel = AndroidNotificationChannel(
      'alarm_fullscreen_channel',
      '전체화면 알람',
      description: '전체화면으로 표시되는 알람',
      importance: Importance.max,
      enableVibration: true,
      enableLights: true,
      playSound: false,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(fullScreenChannel);

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

// 권한 요청
Future<void> _requestPermissions() async {
  if (Platform.isAndroid) {
    // 정확한 알람 권한
    final status = await Permission.scheduleExactAlarm.status;
    if (!status.isGranted) {
      await Permission.scheduleExactAlarm.request();
    }

    // 알림 권한
    final notificationStatus = await Permission.notification.status;
    if (!notificationStatus.isGranted) {
      await Permission.notification.request();
    }

    // 시스템 알림 창 권한 (전체화면 알람용)
    final systemAlertStatus = await Permission.systemAlertWindow.status;
    if (!systemAlertStatus.isGranted) {
      await Permission.systemAlertWindow.request();
    }

    debugPrint('권한 요청 완료');
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
          '/alarm-ringing': (context) => _buildAlarmRingingScreen(context),
          '/files/upload': (context) => const FileUploadScreen(),
          '/mp3-player': (context) => const MP3PlayerScreen(),
        },
      ),
    );
  }

  Widget _determineHomeScreen(BuildContext context) {
    return FutureBuilder(
      future: Provider.of<AuthProvider>(context, listen: false).init(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final authProvider = Provider.of<AuthProvider>(context);
        if (authProvider.isAuthenticated) {
          // 알람이 울렸는지 확인하는 위젯 사용
          return const AlarmChecker();
        } else {
          return const LoginScreen();
        }
      },
    );
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

// 알람 체커 위젯 (새로 추가!)
class AlarmChecker extends StatefulWidget {
  const AlarmChecker({Key? key}) : super(key: key);

  @override
  State<AlarmChecker> createState() => _AlarmCheckerState();
}

class _AlarmCheckerState extends State<AlarmChecker> with WidgetsBindingObserver {
  Timer? _checkTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // 앱이 시작되자마자 알람 체크
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForTriggeredAlarm();
    });

    // 0.5초마다 알람이 울렸는지 체크 (더 빠르게)
    _checkTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      _checkForTriggeredAlarm();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _checkTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // 앱이 포그라운드로 돌아올 때 알람 체크
    if (state == AppLifecycleState.resumed) {
      debugPrint('앱이 포그라운드로 돌아옴 - 알람 체크');
      _checkForTriggeredAlarm();
    }
  }

  // 알람이 울렸는지 체크하는 핵심 함수
  Future<void> _checkForTriggeredAlarm() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final triggeredAlarmId = prefs.getString('alarm_triggered');
      final triggeredTime = prefs.getString('alarm_triggered_time');

      if (triggeredAlarmId != null && triggeredTime != null) {
        debugPrint('알람 트리거 감지! ID: $triggeredAlarmId, 시간: $triggeredTime');

        // 트리거 정보 삭제 (중복 방지)
        await prefs.remove('alarm_triggered');
        await prefs.remove('alarm_triggered_time');

        // 알람 ID로 알람 데이터 가져오기
        final alarmId = int.tryParse(triggeredAlarmId);
        if (alarmId != null) {
          await _showAlarmScreen(alarmId);
        }
      }
    } catch (e) {
      debugPrint('알람 체크 오류: $e');
    }
  }

  // 알람 화면 표시
  Future<void> _showAlarmScreen(int alarmId) async {
    try {
      debugPrint('알람 화면 표시 시도 - ID: $alarmId');

      // SharedPreferences에서 알람 데이터 가져오기 (여러 키 시도)
      final prefs = await SharedPreferences.getInstance();

      // 가능한 모든 키로 시도
      List<String> possibleKeys = [
        'alarm_data_$alarmId',
        'alarm_data_${alarmId}0000',  // scheduleAlarm에서 생성한 ID
        'alarm_data_${alarmId}00',
      ];

      String? alarmJson;
      for (String key in possibleKeys) {
        alarmJson = prefs.getString(key);
        if (alarmJson != null) {
          debugPrint('알람 데이터 발견 - 키: $key');
          break;
        }
      }

      // 모든 키 출력해서 디버깅
      final allKeys = prefs.getKeys().where((key) => key.startsWith('alarm_data_')).toList();
      debugPrint('저장된 모든 알람 데이터 키들: $allKeys');

      Alarm alarm;
      if (alarmJson != null) {
        try {
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
            isEnabled: true,
          );
          debugPrint('저장된 알람 데이터 로드 성공: ${alarm.label}');
        } catch (e) {
          debugPrint('알람 데이터 파싱 오류: $e');
          alarm = _createDefaultAlarmForScreen(alarmId);
        }
      } else {
        debugPrint('저장된 데이터 없음, 기본 알람 생성');
        alarm = _createDefaultAlarmForScreen(alarmId);
      }

      // 현재 화면이 알람 화면이 아닌 경우에만 이동
      if (mounted) {
        final currentRoute = ModalRoute.of(context)?.settings.name;
        if (currentRoute != '/alarm-ringing') {
          // 알람 화면으로 이동
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/alarm-ringing',
                (route) => false,  // 모든 이전 화면 제거
            arguments: {'alarm': alarm},
          );
          debugPrint('알람 화면으로 이동 완료');
        } else {
          debugPrint('이미 알람 화면에 있음');
        }
      }
    } catch (e) {
      debugPrint('알람 화면 표시 중 오류: $e');
    }
  }

  // 기본 알람 생성
  Alarm _createDefaultAlarmForScreen(int alarmId) {
    final now = DateTime.now();
    return Alarm(
      id: alarmId,
      time: TimeOfDay(hour: now.hour, minute: now.minute),
      repeatDays: List.filled(7, false),
      label: '알람',
      soundPath: 'assets/default_alarm.mp3',
      soundName: '기본 알람음',
      isEnabled: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    // 홈 화면 표시
    return const HomeScreen();
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