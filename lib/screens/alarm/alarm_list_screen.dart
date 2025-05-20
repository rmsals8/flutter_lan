// lib/screens/alarm/alarm_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/alarm.dart';
import '../../providers/alarm_provider.dart';
import './alarm_edit_screen.dart';

class AlarmListScreen extends StatefulWidget {
  const AlarmListScreen({Key? key}) : super(key: key);

  @override
  State<AlarmListScreen> createState() => _AlarmListScreenState();
}

class _AlarmListScreenState extends State<AlarmListScreen> {
  @override
  void initState() {
    super.initState();
    // 화면이 로드되면 알람 목록 가져오기
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AlarmProvider>(context, listen: false).initAlarms();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('알람'),
      ),
      body: Consumer<AlarmProvider>(
        builder: (context, alarmProvider, child) {
          if (alarmProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          
          final alarms = alarmProvider.alarms;
          
          return Stack(
            children: [
              // 알람 목록
              alarms.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      itemCount: alarms.length,
                      padding: const EdgeInsets.only(bottom: 80),
                      itemBuilder: (context, index) {
                        final alarm = alarms[index];
                        return _buildAlarmItem(context, alarm, alarmProvider);
                      },
                    ),
              
              // 새 알람 추가 버튼
              Positioned(
                bottom: 16,
                right: 16,
                child: FloatingActionButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AlarmEditScreen(),
                      ),
                    );
                  },
                  backgroundColor: AppTheme.primaryColor,
                  child: const Icon(Icons.add),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
  
  // 알람이 없는 경우 표시할 위젯
  Widget _buildEmptyState() {
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
          ),
          const SizedBox(height: 8),
          const Text(
            '오른쪽 하단의 + 버튼을 눌러\n새 알람을 추가해보세요',
            style: AppTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  // 알람 항목 위젯
  Widget _buildAlarmItem(
    BuildContext context,
    Alarm alarm,
    AlarmProvider alarmProvider,
  ) {
    // 안전한 ID로 키 생성
    String safeKeyString = 'alarm_${alarm.id % 2000000000}';
    
    return Dismissible(
      key: Key(safeKeyString),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        // 즉시 상태 업데이트 후 API 호출
        setState(() {
          // 여기서 먼저 UI에서 제거
          alarmProvider.alarms.removeWhere((a) => a.id == alarm.id);
        });
        
        // 그 다음 실제 삭제 작업 수행
        alarmProvider.deleteAlarm(alarm.id).catchError((error) {
          // 에러 발생 시 처리
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('알람 삭제 실패: $error')),
          );
          
          // 다시 목록 로드 (오류 복구)
          alarmProvider.initAlarms();
        });
        
        // 삭제 완료 메시지 표시
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('알람이 삭제되었습니다')),
        );
      },
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('알람 삭제'),
            content: const Text('이 알람을 삭제하시겠습니까?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
                child: const Text('삭제'),
              ),
            ],
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: 2,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AlarmEditScreen(alarm: alarm),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // 알람 시간 및 정보
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alarm.readableTime,
                        style: AppTheme.titleLarge.copyWith(
                          color: alarm.isEnabled
                              ? AppTheme.primaryColor
                              : Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        alarm.label,
                        style: AppTheme.bodyMedium.copyWith(
                          color: alarm.isEnabled
                              ? AppTheme.textPrimaryColor
                              : Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            alarm.repeatDaysText,
                            style: AppTheme.bodySmall.copyWith(
                              color: alarm.isEnabled
                                  ? AppTheme.textSecondaryColor
                                  : Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: alarm.isEnabled
                                  ? AppTheme.textSecondaryColor
                                  : Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              alarm.soundName,
                              style: AppTheme.bodySmall.copyWith(
                                color: alarm.isEnabled
                                    ? AppTheme.textSecondaryColor
                                    : Colors.grey,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // 활성화/비활성화 스위치
                Switch(
                  value: alarm.isEnabled,
                  onChanged: (value) {
                    alarmProvider.toggleAlarm(alarm);
                  },
                  activeColor: AppTheme.primaryColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}