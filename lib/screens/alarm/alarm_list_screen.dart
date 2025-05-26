// lib/screens/alarm/alarm_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/alarm.dart';
import '../../providers/alarm_provider.dart';
import '../../services/alarm_service.dart';

class AlarmListScreen extends StatefulWidget {
  const AlarmListScreen({Key? key}) : super(key: key);

  @override
  State<AlarmListScreen> createState() => _AlarmListScreenState();
}

class _AlarmListScreenState extends State<AlarmListScreen> {
  @override
  void initState() {
    super.initState();
    // 화면 진입 시 알람 목록 불러오기
    Future.microtask(() {
      Provider.of<AlarmProvider>(context, listen: false).initAlarms();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('알람'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              _navigateToAlarmEdit(context);
            },
            tooltip: '알람 추가',
          ),
        ],
      ),
      body: Consumer<AlarmProvider>(
        builder: (context, alarmProvider, child) {
          final alarms = alarmProvider.alarms;
          
          // 로딩 중
          if (alarmProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          
          // 에러 표시
          if (alarmProvider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(alarmProvider.errorMessage!, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      alarmProvider.initAlarms();
                    },
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            );
          }
          
          // 알람이 없음
          if (alarms.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.alarm_off,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '등록된 알람이 없습니다',
                    style: AppTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '+ 버튼을 눌러 새 알람을 추가해보세요.',
                    style: AppTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('알람 추가'),
                    onPressed: () {
                      _navigateToAlarmEdit(context);
                    },
                  ),
                ],
              ),
            );
          }
          
          // 알람 목록
          return ListView.builder(
            itemCount: alarms.length,
            padding: const EdgeInsets.all(8.0),
            itemBuilder: (context, index) {
              final alarm = alarms[index];
              return _buildAlarmCard(context, alarm);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _navigateToAlarmEdit(context);
        },
        tooltip: '알람 추가',
        child: const Icon(Icons.add),
      ),
    );
  }
  
  // 알람 카드 위젯
  Widget _buildAlarmCard(BuildContext context, Alarm alarm) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _navigateToAlarmEdit(context, alarm: alarm),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 시간 표시
                  Text(
                    alarm.readableTime,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: alarm.isEnabled ? AppTheme.primaryColor : Colors.grey,
                    ),
                  ),
                  
                  // 활성화 스위치
                  Switch(
                    value: alarm.isEnabled,
                    onChanged: (value) {
                      _toggleAlarm(context, alarm);
                    },
                    activeColor: AppTheme.primaryColor,
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // 알람 이름
              Text(
                alarm.label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              
              const SizedBox(height: 4),
              
              // 반복 요일
              Row(
                children: [
                  const Icon(
                    Icons.repeat,
                    size: 14,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    alarm.repeatDaysText,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 4),
              
              // 알람음
              Row(
                children: [
                  const Icon(
                    Icons.music_note,
                    size: 14,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      alarm.soundName,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // 액션 버튼들
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // 알람 테스트 버튼
                  TextButton.icon(
                    icon: const Icon(Icons.play_arrow, size: 18),
                    label: const Text('테스트'),
                    onPressed: () => _testAlarm(context, alarm),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blueGrey,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                  
                  // 알람 삭제 버튼
                  TextButton.icon(
                    icon: const Icon(Icons.delete, size: 18),
                    label: const Text('삭제'),
                    onPressed: () => _deleteAlarm(context, alarm),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // 알람 편집 화면으로 이동
  void _navigateToAlarmEdit(BuildContext context, {Alarm? alarm}) async {
    final result = await Navigator.pushNamed(
      context,
      '/alarms/edit',
      arguments: alarm != null ? {'alarm': alarm} : null,
    );
    
    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('알람이 저장되었습니다.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
  
  // 알람 활성화/비활성화
  void _toggleAlarm(BuildContext context, Alarm alarm) {
    Provider.of<AlarmProvider>(context, listen: false).toggleAlarm(alarm);
  }
  
  // 알람 테스트
  void _testAlarm(BuildContext context, Alarm alarm) async {
    final alarmService = AlarmService();
    
    // 현재 알람음 재생
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('알람음 테스트 중...'),
        action: SnackBarAction(
          label: '중지',
          onPressed: () {
            alarmService.stopAlarmSound();
          },
        ),
        duration: const Duration(seconds: 10),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
    
    await alarmService.playAlarmSound(alarm.soundPath);
    
    // 10초 후 자동 중지
    Future.delayed(const Duration(seconds: 10), () {
      alarmService.stopAlarmSound();
    });
  }
  
  // 알람 삭제
  void _deleteAlarm(BuildContext context, Alarm alarm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('알람 삭제'),
        content: Text('${alarm.label} 알람을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Provider.of<AlarmProvider>(context, listen: false)
                  .deleteAlarm(alarm.id);
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('알람이 삭제되었습니다.'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text(
              '삭제',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}