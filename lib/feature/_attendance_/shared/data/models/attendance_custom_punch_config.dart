import 'package:clover/feature/_attendance_/shared/data/models/attendance_day_time.dart';

/// Своя отметка admin: название + когда ожидается отметка.
class AttendanceCustomPunchConfig {
  const AttendanceCustomPunchConfig({
    required this.label,
    this.id,
    this.scheduledTime,
  });

  final String? id;
  final String label;

  /// Когда работник должен отметиться (например 09:00). null — без фиксированного времени.
  final AttendanceDayTime? scheduledTime;

  bool get hasScheduledTime => scheduledTime != null;

  AttendanceCustomPunchConfig copyWith({
    String? id,
    String? label,
    AttendanceDayTime? scheduledTime,
    bool clearScheduledTime = false,
  }) {
    return AttendanceCustomPunchConfig(
      id: id ?? this.id,
      label: label ?? this.label,
      scheduledTime: clearScheduledTime ? null : (scheduledTime ?? this.scheduledTime),
    );
  }
}
