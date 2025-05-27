// lib/screens/alarm/alarm_ringing_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/theme.dart';
import '../../models/alarm.dart';
import '../../services/alarm_service.dart';
import '../../services/alarm_receiver.dart';

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
  }

  @override
  void dispose() {
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
    } catch (e) {
      debugPrint('화면 깨우기 오류: $e');
    }
  }

  // 알람을 중지하는 기능
  void _stopAlarm() async {
    try {
      // 애니메이션 중지
      _pulseController.stop();

      // 알람 소리 중지 (AlarmReceiver와 AlarmService 둘 다 시도)
      await AlarmReceiver.stopAlarmSound();
      await _alarmService.stopAlarmSound();

      // 진동 중지
      HapticFeedback.lightImpact();

      // 화면 닫기
      if (mounted) {
        Navigator.of(context).pop();
      }

      debugPrint('알람이 중지되었습니다.');
    } catch (e) {
      debugPrint('알람 중지 오류: $e');
    }
  }

  // 스누즈 기능 (5분 후에 다시 알람)
  void _snoozeAlarm() async {
    try {
      // 현재 알람 소리 중지
      await AlarmReceiver.stopAlarmSound();
      await _alarmService.stopAlarmSound();

      // 5분 후 알람 다시 설정
      final snoozeTime = DateTime.now().add(const Duration(minutes: 5));
      final snoozeAlarm = widget.alarm.copyWith(
        time: TimeOfDay(hour: snoozeTime.hour, minute: snoozeTime.minute),
      );

      await _alarmService.scheduleAlarm(snoozeAlarm);

      // 스낵바로 알림
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('5분 후에 다시 알람이 울립니다.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );

        // 화면 닫기
        Navigator.of(context).pop();
      }

      debugPrint('스누즈 설정: 5분 후 알람');
    } catch (e) {
      debugPrint('스누즈 설정 오류: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 두 번째 사진처럼 파란색 배경
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

                // 현재 날짜 (두 번째 사진 스타일)
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

                // 현재 시간 (큰 글씨 - 두 번째 사진 스타일)
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

                // 귀여운 캐릭터 영역 (두 번째 사진의 토끼 캐릭터 대신)
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
                      // 상단 캐릭터 영역 (첫 번째 토끼)
                      Container(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            // 토끼 이모지로 대체 (또는 커스텀 아이콘)
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
                                'You can do it.',
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

                      // 하단 캐릭터 영역 (두 번째 토끼)
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
                                "You're so cool.",
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

                // 알람 끄기 버튼 (두 번째 사진 스타일 - 빨간색)
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

                // 스누즈 버튼 (투명한 테두리 버튼)
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
    );
  }

  // 현재 날짜를 문자열로 반환하는 기능 (두 번째 사진 스타일)
  String _getCurrentDateString() {
    final now = DateTime.now();
    final weekdays = ['일요일', '월요일', '화요일', '수요일', '목요일', '금요일', '토요일'];
    final weekday = weekdays[now.weekday % 7];

    return '${now.month}월 ${now.day}일 $weekday';
  }

  // 현재 시간을 문자열로 반환하는 기능 (두 번째 사진 스타일)
  String _getCurrentTimeString() {
    final now = DateTime.now();
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }
}