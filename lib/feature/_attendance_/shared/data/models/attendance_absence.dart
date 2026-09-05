enum AttendanceAbsenceKind {
  dayOff,
  vacation,
  sick,
}

extension AttendanceAbsenceKindX on AttendanceAbsenceKind {
  String get labelRu => switch (this) {
        AttendanceAbsenceKind.dayOff => 'Выходной',
        AttendanceAbsenceKind.vacation => 'Отпуск',
        AttendanceAbsenceKind.sick => 'Больничный',
      };

  String get key => switch (this) {
        AttendanceAbsenceKind.dayOff => 'day_off',
        AttendanceAbsenceKind.vacation => 'vacation',
        AttendanceAbsenceKind.sick => 'sick',
      };

  static AttendanceAbsenceKind fromKey(String raw) => switch (raw) {
        'vacation' => AttendanceAbsenceKind.vacation,
        'sick' => AttendanceAbsenceKind.sick,
        _ => AttendanceAbsenceKind.dayOff,
      };
}

class AttendanceAbsenceEntry {
  const AttendanceAbsenceEntry({
    required this.id,
    required this.workplaceId,
    required this.workerId,
    required this.kind,
    required this.startDate,
    required this.endDate,
    this.note,
  });

  final String id;
  final String workplaceId;
  final String workerId;
  final AttendanceAbsenceKind kind;
  final DateTime startDate;
  final DateTime endDate;
  final String? note;

  bool covers(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    return !key.isBefore(start) && !key.isAfter(end);
  }
}
