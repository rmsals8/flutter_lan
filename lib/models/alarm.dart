// lib/models/alarm.dart
import 'package:flutter/material.dart';

class Alarm {
  final int id;
  final TimeOfDay time;
  final bool isEnabled;
  final List<bool> repeatDays; // [월, 화, 수, 목, 금, 토, 일]
  final String label;
  final String soundPath; // MP3 파일 경로
  final String soundName; // MP3 파일 이름

  Alarm({
    required this.id,
    required this.time,
    this.isEnabled = true,
    required this.repeatDays,
    this.label = '알람',
    required this.soundPath,
    required this.soundName,
  });

  Alarm copyWith({
    int? id,
    TimeOfDay? time,
    bool? isEnabled,
    List<bool>? repeatDays,
    String? label,
    String? soundPath,
    String? soundName,
  }) {
    return Alarm(
      id: id ?? this.id,
      time: time ?? this.time,
      isEnabled: isEnabled ?? this.isEnabled,
      repeatDays: repeatDays ?? List<bool>.from(this.repeatDays),
      label: label ?? this.label,
      soundPath: soundPath ?? this.soundPath,
      soundName: soundName ?? this.soundName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hour': time.hour,
      'minute': time.minute,
      'isEnabled': isEnabled,
      'repeatDays': repeatDays,
      'label': label,
      'soundPath': soundPath,
      'soundName': soundName,
    };
  }

  factory Alarm.fromJson(Map<String, dynamic> json) {
    // repeatDays가 List<dynamic>으로 들어올 수 있으므로 명시적 변환
    final List<dynamic> rawRepeatDays = json['repeatDays'];
    final List<bool> parsedRepeatDays = rawRepeatDays.map((day) => day as bool).toList();
    
    return Alarm(
      id: json['id'],
      time: TimeOfDay(hour: json['hour'], minute: json['minute']),
      isEnabled: json['isEnabled'],
      repeatDays: parsedRepeatDays,
      label: json['label'],
      soundPath: json['soundPath'],
      soundName: json['soundName'],
    );
  }

  String get readableTime {
    final hour = time.hour > 12 ? time.hour - 12 : time.hour;
    final period = time.hour >= 12 ? '오후' : '오전';
    final minute = time.minute.toString().padLeft(2, '0');
    return '$period ${hour == 0 ? 12 : hour}:$minute';
  }

  String get repeatDaysText {
    if (!repeatDays.contains(true)) {
      return '반복 없음';
    }

    final days = ['월', '화', '수', '목', '금', '토', '일'];
    final selectedDays = <String>[];

    for (int i = 0; i < repeatDays.length; i++) {
      if (repeatDays[i]) {
        selectedDays.add(days[i]);
      }
    }

    if (selectedDays.length == 7) {
      return '매일';
    } else if (selectedDays.length == 5 && 
              repeatDays[0] && repeatDays[1] && repeatDays[2] && 
              repeatDays[3] && repeatDays[4]) {
      return '평일';
    } else if (selectedDays.length == 2 && repeatDays[5] && repeatDays[6]) {
      return '주말';
    }

    return selectedDays.join(', ');
  }
}