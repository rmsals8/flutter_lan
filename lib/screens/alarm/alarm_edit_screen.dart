// lib/screens/alarm/alarm_edit_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/alarm.dart';
import '../../models/user_file.dart';
import '../../providers/alarm_provider.dart';
import '../../providers/file_provider.dart';
import 'mp3_selector_screen.dart';

class AlarmEditScreen extends StatefulWidget {
  final Alarm? alarm; // 수정 모드인 경우 알람 정보 전달

  const AlarmEditScreen({Key? key, this.alarm}) : super(key: key);

  @override
  State<AlarmEditScreen> createState() => _AlarmEditScreenState();
}

class _AlarmEditScreenState extends State<AlarmEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TimeOfDay _selectedTime;
  late String _label;
  late List<bool> _repeatDays;
  late bool _isEnabled;
  late String _soundPath;
  late String _soundName;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    
    // 수정 모드인 경우 알람 정보 로드
    if (widget.alarm != null) {
      _selectedTime = widget.alarm!.time;
      _label = widget.alarm!.label;
      _repeatDays = List.from(widget.alarm!.repeatDays);
      _isEnabled = widget.alarm!.isEnabled;
      _soundPath = widget.alarm!.soundPath;
      _soundName = widget.alarm!.soundName;
    } else {
      // 새 알람 기본값
      final now = TimeOfDay.now();
      _selectedTime = TimeOfDay(hour: now.hour, minute: now.minute);
      _label = '알람';
      _repeatDays = List.filled(7, false);
      _isEnabled = true;
      _soundPath = '';
      _soundName = '기본 알람음';
    }
    
    // 오디오 파일 목록 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FileProvider>(context, listen: false).fetchAudioFiles();
    });
  }

  // 시간 선택 다이얼로그 표시
  Future<void> _selectTime() async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    
    if (pickedTime != null && pickedTime != _selectedTime) {
      setState(() {
        _selectedTime = pickedTime;
      });
    }
  }
  
  // 알람 저장
 // 알람 저장
Future<void> _saveAlarm() async {
  if (!_formKey.currentState!.validate()) {
    return;
  }
  
  setState(() {
    _isLoading = true;
  });
  
  try {
    final alarmProvider = Provider.of<AlarmProvider>(context, listen: false);
    
    if (widget.alarm != null) {
      // 알람 수정
      final updatedAlarm = Alarm(
        id: widget.alarm!.id % 2000000000, // 32비트 정수 범위 내로 제한
        time: _selectedTime,
        label: _label,
        repeatDays: _repeatDays,
        isEnabled: _isEnabled,
        soundPath: _soundPath,
        soundName: _soundName,
      );
      
      await alarmProvider.updateAlarm(updatedAlarm);
    } else {
      // 새 알람 추가
      final newAlarm = Alarm(
        id: DateTime.now().millisecondsSinceEpoch % 2000000000, // 32비트 정수 범위 내로 제한
        time: _selectedTime,
        label: _label,
        repeatDays: _repeatDays,
        isEnabled: _isEnabled,
        soundPath: _soundPath,
        soundName: _soundName,
      );
      
      await alarmProvider.addAlarm(newAlarm);
    }
    
    if (mounted) {
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.alarm != null ? '알람이 수정되었습니다' : '새 알람이 추가되었습니다'),
          backgroundColor: AppTheme.secondaryColor,
        ),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('알람 저장 오류: ${e.toString()}'),
        backgroundColor: AppTheme.errorColor,
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
  
  // MP3 파일 선택 화면으로 이동
  Future<void> _selectSound() async {
    final selectedSound = await Navigator.push<Map<String, String>>(
      context,
      MaterialPageRoute(
        builder: (context) => const MP3SelectorScreen(),
      ),
    );
    
    if (selectedSound != null) {
      setState(() {
        _soundPath = selectedSound['path']!;
        _soundName = selectedSound['name']!;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(widget.alarm != null ? '알람 수정' : '새 알람'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _isLoading ? null : _saveAlarm,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 시간 선택
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _selectTime,
                      child: Text(
                        _selectedTime.format(context),
                        style: TextStyle(
                          fontSize: 60,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _selectTime,
                      child: const Text('시간 선택'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // 알람 이름
              TextFormField(
                initialValue: _label,
                decoration: const InputDecoration(
                  labelText: '알람 이름',
                  hintText: '알람 이름을 입력하세요',
                  prefixIcon: Icon(Icons.label),
                ),
                onChanged: (value) {
                  _label = value;
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '알람 이름을 입력해주세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              
              // 반복 설정
              Text(
                '반복',
                style: AppTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // 빠른 선택 버튼
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildQuickSelectButton('매일', () {
                            setState(() {
                              _repeatDays = List.filled(7, true);
                            });
                          }),
                          _buildQuickSelectButton('평일', () {
                            setState(() {
                              _repeatDays = [true, true, true, true, true, false, false];
                            });
                          }),
                          _buildQuickSelectButton('주말', () {
                            setState(() {
                              _repeatDays = [false, false, false, false, false, true, true];
                            });
                          }),
                          _buildQuickSelectButton('없음', () {
                            setState(() {
                              _repeatDays = List.filled(7, false);
                            });
                          }),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    
                    // 요일 선택
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildDaySelector(0, '월'),
                        _buildDaySelector(1, '화'),
                        _buildDaySelector(2, '수'),
                        _buildDaySelector(3, '목'),
                        _buildDaySelector(4, '금'),
                        _buildDaySelector(5, '토'),
                        _buildDaySelector(6, '일'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // 알람음 선택
              Text(
                '알람음',
                style: AppTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ListTile(
                  leading: const Icon(Icons.music_note),
                  title: Text(_soundName),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: _selectSound,
                ),
              ),
              const SizedBox(height: 24),
              
              // 알람 활성화 설정
              SwitchListTile(
                title: const Text('알람 활성화'),
                value: _isEnabled,
                onChanged: (value) {
                  setState(() {
                    _isEnabled = value;
                  });
                },
                secondary: Icon(
                  _isEnabled ? Icons.alarm_on : Icons.alarm_off,
                  color: _isEnabled ? AppTheme.primaryColor : Colors.grey,
                ),
                activeColor: AppTheme.primaryColor,
              ),
              
              // 저장 버튼
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveAlarm,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(widget.alarm != null ? '알람 수정' : '알람 추가'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // 요일 선택 버튼
  Widget _buildDaySelector(int index, String label) {
    return InkWell(
      onTap: () {
        setState(() {
          _repeatDays[index] = !_repeatDays[index];
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 40,
        height: 40,
        margin: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _repeatDays[index] ? AppTheme.primaryColor : Colors.transparent,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: _repeatDays[index] ? Colors.white : AppTheme.textSecondaryColor,
            ),
          ),
        ),
      ),
    );
  }
  
  // 빠른 선택 버튼
  Widget _buildQuickSelectButton(String label, VoidCallback onPressed) {
    return TextButton(
      onPressed: onPressed,
      child: Text(label),
    );
  }
}