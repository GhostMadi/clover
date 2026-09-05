enum AttendanceOvertimeStatus {
  pending,
  approved,
  rejected,
}

extension AttendanceOvertimeStatusX on AttendanceOvertimeStatus {
  String get labelRu => switch (this) {
        AttendanceOvertimeStatus.pending => 'Ожидает',
        AttendanceOvertimeStatus.approved => 'Утверждено',
        AttendanceOvertimeStatus.rejected => 'Отклонено',
      };
}

class AttendanceOvertimeEntry {
  const AttendanceOvertimeEntry({
    required this.id,
    required this.workplaceId,
    required this.workerId,
    required this.workerName,
    required this.date,
    required this.hours,
    this.status = AttendanceOvertimeStatus.pending,
  });

  final String id;
  final String workplaceId;
  final String workerId;
  final String workerName;
  final DateTime date;
  final int hours;
  final AttendanceOvertimeStatus status;

  AttendanceOvertimeEntry copyWith({AttendanceOvertimeStatus? status}) {
    return AttendanceOvertimeEntry(
      id: id,
      workplaceId: workplaceId,
      workerId: workerId,
      workerName: workerName,
      date: date,
      hours: hours,
      status: status ?? this.status,
    );
  }
}
