import 'package:clover/feature/_attendance_/shared/data/models/attendance_punch_type.dart';

/// Локально: пора отметиться (для bottom sheet).
enum AttendancePendingKind { clockIn, clockOut }

class AttendancePendingPunch {
  const AttendancePendingPunch({
    required this.workplaceId,
    required this.workplaceName,
    required this.kind,
  });

  final String workplaceId;
  final String workplaceName;
  final AttendancePendingKind kind;

  String get actionLabel => switch (kind) {
        AttendancePendingKind.clockIn => AttendancePunchType.clockIn.labelRu,
        AttendancePendingKind.clockOut => AttendancePunchType.clockOut.labelRu,
      };

  String get prompt => switch (kind) {
        AttendancePendingKind.clockIn => 'Отметьте приход',
        AttendancePendingKind.clockOut => 'Отметьте уход',
      };
}
