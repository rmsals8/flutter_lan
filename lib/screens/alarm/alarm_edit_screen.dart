// lib/screens/alarm/alarm_edit_screen.dart (계속)
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/theme.dart';
import '../../models/alarm.dart';
import '../../providers/alarm_provider.dart';

class AlarmEditScreen extends StatefulWidget {
  const AlarmEditScreen({Key? key}) : super(key: key);

  @override
  State<AlarmEditScreen> createState() => _AlarmEditScreenState();
}

class _AlarmEditScreenState extends State<AlarmEditScreen> {
  // 알람 데이터
  late Alarm _alarm;
  
  // 폼 컨트롤러
  final TextEditingController _labelController = TextEditingController();
  
  // 초기 상태 (신규 알람 또는 편집)
  bool _isNewAlarm = true;
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    // 기본 알람 데이터 초기화
    _alarm = Alarm(
      id: 0,
      time: TimeOfDay.now(),
      repeatDays: List.filled(7, false),
      label: '알람',
      soundPath: 'assets/default_alarm.mp3',
      soundName: '기본 알람음',
    );
    
    _labelController.text = _alarm.label;
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // 라우트 파라미터 확인
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null && args is Map<String, dynamic>) {
      // 기존 알람 편집 모드
      if (args.containsKey('alarm')) {
        final Alarm existingAlarm = args['alarm'];
        setState(() {
          _alarm = existingAlarm;
          _isNewAlarm = false;
          _labelController.text = existingAlarm.label;
        });
      }
    }
  }
  
  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }
  
  // 알람 저장
  Future<void> _saveAlarm() async {
    if (_labelController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('알람 이름을 입력해주세요.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final alarmProvider = Provider.of<AlarmProvider>(context, listen: false);
      
      // 알람 데이터 업데이트
      final updatedAlarm = _alarm.copyWith(
        label: _labelController.text,
      );
      
      if (_isNewAlarm) {
        await alarmProvider.addAlarm(updatedAlarm);
      } else {
        await alarmProvider.updateAlarm(updatedAlarm);
      }
      
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('알람 저장 오류: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  // 시간 선택
  Future<void> _selectTime() async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _alarm.time,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (pickedTime != null && pickedTime != _alarm.time) {
      setState(() {
        _alarm = _alarm.copyWith(time: pickedTime);
      });
    }
  }
  
  // 알람음 선택
  Future<void> _selectSound() async {
    final result = await Navigator.pushNamed(
      context, 
      '/alarms/sound',
      arguments: {'selectedSoundPath': _alarm.soundPath},
    );
    
    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _alarm = _alarm.copyWith(
          soundPath: result['soundPath'],
          soundName: result['soundName'],
        );
      });
    }
  }
  
  // 저장된 MP3 파일 목록을 가져오는 메서드
  Future<List<Map<String, dynamic>>> _getSavedSounds() async {
    final prefs = await SharedPreferences.getInstance();
    final allKeys = prefs.getKeys();
    
    // 'alarm_sound_' 접두어로 저장된 키 필터링
    final soundKeys = allKeys.where((key) => key.startsWith('alarm_sound_')).toList();
    
    final sounds = <Map<String, dynamic>>[];
    
    // 기본 사운드 추가
    sounds.add({
      'id': 'default',
      'path': 'assets/default_alarm.mp3',
      'name': '기본 알람음',
    });
    
    // 저장된 사운드 추가
    for (final key in soundKeys) {
      final path = prefs.getString(key) ?? '';
      if (path.isNotEmpty) {
        final file = File(path);
        if (await file.exists()) {
          final fileName = path.split('/').last;
          sounds.add({
            'id': key.replaceFirst('alarm_sound_', ''),
            'path': path,
            'name': fileName,
          });
        }
      }
    }
    
    return sounds;
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isNewAlarm ? '알람 추가' : '알람 편집'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _isLoading ? null : _saveAlarm,
            tooltip: '저장',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 시간 선택
                  InkWell(
                    onTap: _selectTime,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 32.0),
                      alignment: Alignment.center,
                      child: Text(
                        _alarm.readableTime,
                        style: const TextStyle(
                          fontSize: 50,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // 반복 요일 선택
                  const Text(
                    '반복',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // 요일 선택 UI
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(7, (index) {
                      final dayNames = ['월', '화', '수', '목', '금', '토', '일'];
                      return _buildDayButton(index, dayNames[index]);
                    }),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // 알람 이름 입력
                  TextField(
                    controller: _labelController,
                    decoration: const InputDecoration(
                      labelText: '알람 이름',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.label),
                    ),
                    maxLength: 30,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // 알람음 선택
                  ListTile(
                    title: const Text('알람음'),
                    subtitle: Text(_alarm.soundName),
                    leading: const Icon(Icons.music_note),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _selectSound,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // 알람 활성화 스위치
                  SwitchListTile(
                    title: const Text('알람 활성화'),
                    value: _alarm.isEnabled,
                    onChanged: (value) {
                      setState(() {
                        _alarm = _alarm.copyWith(isEnabled: value);
                      });
                    },
                    secondary: Icon(
                      _alarm.isEnabled ? Icons.alarm_on : Icons.alarm_off,
                      color: _alarm.isEnabled ? AppTheme.primaryColor : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
  
  // 요일 선택 버튼
  Widget _buildDayButton(int dayIndex, String dayName) {
    final isSelected = _alarm.repeatDays[dayIndex];
    
    return GestureDetector(
      onTap: () {
        setState(() {
          final newRepeatDays = List<bool>.from(_alarm.repeatDays);
          newRepeatDays[dayIndex] = !newRepeatDays[dayIndex];
          _alarm = _alarm.copyWith(repeatDays: newRepeatDays);
        });
      },
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey,
          ),
        ),
        child: Center(
          child: Text(
            dayName,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[800],
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}