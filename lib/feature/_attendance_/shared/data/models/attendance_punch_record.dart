import 'package:clover/feature/_attendance_/shared/data/models/attendance_punch_type.dart';

class AttendancePunchRecord {
  const AttendancePunchRecord({
    required this.id,
    required this.workplaceId,
    required this.workerId,
    required this.type,
    required this.at,
    this.cancelled = false,
    this.cancelComment,
    this.clientPunchId,
    this.closeReason,
  });

  final String id;
  final String workplaceId;
  final String workerId;
  final AttendancePunchType type;
  final DateTime at;
  final bool cancelled;
  final String? cancelComment;
  final String? clientPunchId;
  /// EN: auto_closed | admin_closed
  final String? closeReason;

  AttendancePunchRecord copyWith({
    bool? cancelled,
    String? cancelComment,
    String? clientPunchId,
    String? closeReason,
  }) {
    return AttendancePunchRecord(
      id: id,
      workplaceId: workplaceId,
      workerId: workerId,
      type: type,
      at: at,
      cancelled: cancelled ?? this.cancelled,
      cancelComment: cancelComment ?? this.cancelComment,
      clientPunchId: clientPunchId ?? this.clientPunchId,
      closeReason: closeReason ?? this.closeReason,
    );
  }

  String get formattedAt {
    final d = at;
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final hh = d.hour.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');
    return '$dd.$mm $hh:$min';
  }
}
