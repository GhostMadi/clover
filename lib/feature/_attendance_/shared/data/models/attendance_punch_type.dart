/// Системные отметки — фиксированные ключи (enum), не свободный текст.
enum AttendanceSystemPunchCode {
  clockIn,
  clockOut;

  String get key => switch (this) {
        AttendanceSystemPunchCode.clockIn => 'clock_in',
        AttendanceSystemPunchCode.clockOut => 'clock_out',
      };

  String get labelRu => switch (this) {
        AttendanceSystemPunchCode.clockIn => 'Пришёл',
        AttendanceSystemPunchCode.clockOut => 'Ушёл',
      };

  AttendancePunchType toType() => AttendancePunchType(
        key: key,
        labelRu: labelRu,
        isSystem: true,
        systemCode: this,
      );
}

/// Тип отметки посещаемости (ключ = бэк).
class AttendancePunchType {
  const AttendancePunchType({
    required this.key,
    required this.labelRu,
    this.isSystem = false,
    this.systemCode,
  });

  final String key;
  final String labelRu;
  final bool isSystem;
  final AttendanceSystemPunchCode? systemCode;

  static const clockIn = AttendancePunchType(
    key: 'clock_in',
    labelRu: 'Пришёл',
    isSystem: true,
    systemCode: AttendanceSystemPunchCode.clockIn,
  );

  static const clockOut = AttendancePunchType(
    key: 'clock_out',
    labelRu: 'Ушёл',
    isSystem: true,
    systemCode: AttendanceSystemPunchCode.clockOut,
  );

  factory AttendancePunchType.custom(String labelRu) {
    final trimmed = labelRu.trim();
    final slug = trimmed
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-zа-яё0-9]+', caseSensitive: false), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return AttendancePunchType(
      key: 'custom_${slug.isEmpty ? 'note' : slug}',
      labelRu: trimmed,
    );
  }

  bool get isClockIn => key == clockIn.key;
  bool get isClockOut => key == clockOut.key;
}
