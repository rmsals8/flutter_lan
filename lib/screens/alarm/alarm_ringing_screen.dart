// lib/screens/alarm/alarm_ringing_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../config/theme.dart';
import '../../models/alarm.dart';
import '../../services/alarm_service.dart';
import '../../services/alarm_receiver.dart';
import '../../main.dart'; // flutterLocalNotificationsPlugin 사용

class AlarmRingingScreen extends StatefulWidget {
  final Alarm alarm;

  const AlarmRingingScreen({
    Key? key,
    required this.alarm,
  }) : super(key: key);

  @override
  State<AlarmRingingScreen> createState() => _AlarmRingingScreenState();
}

class _AlarmRingingScreenState extends State<AlarmRingingScreen>
    with TickerProviderStateMixin {

  final AlarmService _alarmService = AlarmService();
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    debugPrint('AlarmRingingScreen: 초기화 시작');

    // 화면이 켜지도록 설정
    _wakeUpScreen();

    // 맥박 애니메이션 (알람 버튼이 깜박이는 효과)
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.9,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // 슬라이드 애니메이션 (화면이 아래에서 위로 올라오는 효과)
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    ));

    // 애니메이션 시작
    _pulseController.repeat(reverse: true);
    _slideController.forward();

    // 진동 시작
    _startVibration();

    debugPrint('AlarmRingingScreen: 초기화 완료');
  }

  @override
  void dispose() {
    debugPrint('AlarmRingingScreen: dispose 시작');
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  // 진동 시작 기능
  void _startVibration() {
    // 강한 진동 패턴
    HapticFeedback.heavyImpact();

    // 계속 진동하도록 설정 (2초마다 반복)
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        HapticFeedback.heavyImpact();
        _startVibration(); // 재귀 호출로 계속 진동
      }
    });
  }

  // 화면을 켜고 잠금화면 위에 표시하는 기능
  void _wakeUpScreen() {
    try {
      // 화면을 켜는 기능 (안드로이드용)
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
      debugPrint('AlarmRingingScreen: 화면 깨우기 완료');
    } catch (e) {
      debugPrint('AlarmRingingScreen: 화면 깨우기 오류: $e');
    }
  }

  // 알람을 중지하는 기능 (가장 중요한 부분!)
  void _stopAlarm() async {
    try {
      debugPrint('AlarmRingingScreen: 알람 중지 시작');

      // 1. 애니메이션 중지
      _pulseController.stop();

      // 2. 알람 소리 중지 (AlarmReceiver와 AlarmService 둘 다 시도)
      await AlarmReceiver.stopAlarmSound();
      await _alarmService.stopAlarmSound();
      debugPrint('AlarmRingingScreen: 알람음 중지 완료');

      // 3. 진동 중지
      HapticFeedback.lightImpact();

      // 4. 모든 알람 관련 알림 취소
      await _cancelAllAlarmNotifications();

      // 5. 성공 메시지 표시
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('알람이 중지되었습니다.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );

        // 6. 잠시 기다린 후 화면 닫기
        await Future.delayed(const Duration(milliseconds: 500));

        // 7. 홈 화면으로 이동 (알람 화면 완전히 제거)
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/home',
              (route) => false, // 모든 이전 화면 제거
        );
      }

      debugPrint('AlarmRingingScreen: 알람 중지 완료');
    } catch (e) {
      debugPrint('AlarmRingingScreen: 알람 중지 오류: $e');

      // 오류가 발생해도 화면은 닫기
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/home',
              (route) => false,
        );
      }
    }
  }

  // 모든 알람 관련 알림 취소
  Future<void> _cancelAllAlarmNotifications() async {
    try {
      // 현재 알람 ID로 된 모든 알림 취소
      await flutterLocalNotificationsPlugin.cancel(widget.alarm.id);

      // 추가로 관련된 ID들도 취소 (혹시 모를 중복 방지)
      await flutterLocalNotificationsPlugin.cancel(widget.alarm.id + 1000);
      await flutterLocalNotificationsPlugin.cancel(widget.alarm.id + 2000);

      debugPrint('AlarmRingingScreen: 모든 알람 알림 취소 완료');
    } catch (e) {
      debugPrint('AlarmRingingScreen: 알림 취소 오류: $e');
    }
  }

  // 스누즈 기능 (5분 후에 다시 알람)
  void _snoozeAlarm() async {
    try {
      debugPrint('AlarmRingingScreen: 스누즈 시작');

      // 1. 현재 알람 소리 중지
      await AlarmReceiver.stopAlarmSound();
      await _alarmService.stopAlarmSound();

      // 2. 모든 알람 알림 취소
      await _cancelAllAlarmNotifications();

      // 3. 5분 후 알람 다시 설정
      final snoozeTime = DateTime.now().add(const Duration(minutes: 5));
      final snoozeAlarm = widget.alarm.copyWith(
        time: TimeOfDay(hour: snoozeTime.hour, minute: snoozeTime.minute),
      );

      await _alarmService.scheduleAlarm(snoozeAlarm);
      debugPrint('AlarmRingingScreen: 스누즈 알람 예약 완료');

      // 4. 스낵바로 알림
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('5분 후에 다시 알람이 울립니다.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );

        // 5. 잠시 기다린 후 홈 화면으로 이동
        await Future.delayed(const Duration(milliseconds: 500));

        Navigator.of(context).pushNamedAndRemoveUntil(
          '/home',
              (route) => false,
        );
      }

      debugPrint('AlarmRingingScreen: 스누즈 완료');
    } catch (e) {
      debugPrint('AlarmRingingScreen: 스누즈 설정 오류: $e');

      // 오류가 발생해도 화면은 닫기
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/home',
              (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // 뒤로가기 버튼 방지 (알람을 의도적으로 끄도록 유도)
      onWillPop: () async {
        debugPrint('AlarmRingingScreen: 뒤로가기 시도됨 - 무시');
        return false;
      },
      child: Scaffold(
        // 알람 화면은 파란색 배경
        backgroundColor: const Color(0xFF3498DB),
        body: SlideTransition(
          position: _slideAnimation,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // 상단 여백
                  const SizedBox(height: 40),

                  // 현재 날짜
                  Text(
                    _getCurrentDateString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 현재 시간 (큰 글씨)
                  Text(
                    _getCurrentTimeString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 64,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -2.0,
                    ),
                  ),

                  const SizedBox(height: 60),

                  // 귀여운 캐릭터 영역
                  Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 상단 캐릭터 영역
                        Container(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              // 토끼 이모지
                              const Text(
                                '🐰',
                                style: TextStyle(fontSize: 48),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'Good morning!',
                                  style: TextStyle(
                                    color: Color(0xFF3498DB),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // 하단 캐릭터 영역
                        Container(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              const Text(
                                '🐰',
                                style: TextStyle(fontSize: 48),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  "Time to wake up!",
                                  style: TextStyle(
                                    color: Color(0xFF3498DB),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // 알람 이름 표시 영역
                  if (widget.alarm.label.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Text(
                        widget.alarm.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  // 알람 끄기 버튼 (가장 중요한 부분!)
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Container(
                          width: double.infinity,
                          height: 60,
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          child: ElevatedButton(
                            onPressed: _stopAlarm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE74C3C), // 빨간색
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 8,
                              shadowColor: Colors.black.withOpacity(0.3),
                            ),
                            child: const Text(
                              '알람 끄기',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // 스누즈 버튼
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: _snoozeAlarm,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white, width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: const Text(
                        '5분 후 다시 알림',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 현재 날짜를 문자열로 반환하는 기능
  String _getCurrentDateString() {
    final now = DateTime.now();
    final weekdays = ['일요일', '월요일', '화요일', '수요일', '목요일', '금요일', '토요일'];
    final weekday = weekdays[now.weekday % 7];

    return '${now.month}월 ${now.day}일 $weekday';
  }

  // 현재 시간을 문자열로 반환하는 기능
  String _getCurrentTimeString() {
    final now = DateTime.now();
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }
}