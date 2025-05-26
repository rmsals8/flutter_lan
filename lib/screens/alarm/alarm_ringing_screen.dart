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
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // 슬라이드 애니메이션 (화면이 아래에서 위로 올라오는 효과)
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
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
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
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
      // 알람 소리 중지 (AlarmReceiver와 AlarmService 둘 다 시도)
      await AlarmReceiver.stopAlarmSound();
      await _alarmService.stopAlarmSound();

      // 진동 중지 (있다면)
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
      backgroundColor: AppTheme.primaryColor,
      body: SlideTransition(
        position: _slideAnimation,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // 상단 시간 표시
                const SizedBox(height: 40),

                // 현재 날짜
                Text(
                  _getCurrentDateString(),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 16),

                // 현재 시간 (큰 글씨)
                Text(
                  _getCurrentTimeString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 60),

                // 귀여운 캐릭터나 이미지 자리 (일단 아이콘으로 대체)
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.alarm,
                        size: 80,
                        color: Colors.white,
                      ),
                      SizedBox(height: 16),
                      Text(
                        '일어날 시간이에요!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // 알람 이름
                Text(
                  widget.alarm.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 20),

                // 알람 시간
                Text(
                  widget.alarm.readableTime,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 18,
                  ),
                ),

                const Spacer(),

                // 알람 끄기 버튼 (맥박 애니메이션 적용)
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
                            backgroundColor: Colors.red,
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
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
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