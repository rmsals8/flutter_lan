// lib/providers/alarm_provider.dart
import 'package:flutter/material.dart';
import '../models/alarm.dart';
import '../services/alarm_service.dart';

class AlarmProvider extends ChangeNotifier {
  final AlarmService _alarmService = AlarmService();
  List<Alarm> _alarms = [];
  bool _isLoading = false;
  
  List<Alarm> get alarms => _alarms;
  bool get isLoading => _isLoading;
  
  // 알람 초기화 및 불러오기
  Future<void> initAlarms() async {
    _setLoading(true);
    
    try {
      await _alarmService.initialize();
      _alarms = await _alarmService.loadAlarms();
      
      // 날짜순 정렬 (시간 오름차순)
      _alarms.sort((a, b) {
        final aTime = a.time.hour * 60 + a.time.minute;
        final bTime = b.time.hour * 60 + b.time.minute;
        return aTime.compareTo(bTime);
      });
      
      notifyListeners();
    } catch (e) {
      debugPrint('알람 초기화 오류: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  // 알람 추가
  Future<void> addAlarm(Alarm alarm) async {
    _setLoading(true);
    
    try {
      await _alarmService.addAlarm(alarm);
      await initAlarms(); // 알람 목록 새로고침
    } catch (e) {
      debugPrint('알람 추가 오류: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  // 알람 업데이트
  Future<void> updateAlarm(Alarm alarm) async {
    _setLoading(true);
    
    try {
      await _alarmService.updateAlarm(alarm);
      await initAlarms(); // 알람 목록 새로고침
    } catch (e) {
      debugPrint('알람 업데이트 오류: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  // 알람 삭제
  Future<void> deleteAlarm(int alarmId) async {
    _setLoading(true);
    
    try {
      await _alarmService.deleteAlarm(alarmId);
      await initAlarms(); // 알람 목록 새로고침
    } catch (e) {
      debugPrint('알람 삭제 오류: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  // 알람 활성화/비활성화 토글
  Future<void> toggleAlarm(Alarm alarm) async {
    final updatedAlarm = alarm.copyWith(isEnabled: !alarm.isEnabled);
    await updateAlarm(updatedAlarm);
  }
  
  // 로딩 상태 설정
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}