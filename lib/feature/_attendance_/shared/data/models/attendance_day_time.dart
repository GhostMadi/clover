import 'package:flutter/material.dart';

/// Время суток для расписания отметки (без даты).
class AttendanceDayTime {
  const AttendanceDayTime({required this.hour, required this.minute});

  final int hour;
  final int minute;

  factory AttendanceDayTime.fromTimeOfDay(TimeOfDay time) {
    return AttendanceDayTime(hour: time.hour, minute: time.minute);
  }

  TimeOfDay toTimeOfDay() => TimeOfDay(hour: hour, minute: minute);

  String get labelRu {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
