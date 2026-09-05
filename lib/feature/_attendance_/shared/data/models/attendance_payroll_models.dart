/// Правила влияния посещаемости на зарплату (mock UI, v1).
class AttendancePayrollRules {
  const AttendancePayrollRules({
    this.lateDeductsPay = false,
    this.overtimeAddsPay = false,
    this.absenceDeductsPay = true,
    this.partialDayDeductsPay = false,
    this.lateDeductPerMinute = 50,
    this.overtimeBonusPerHour = 1500,
    this.absenceDeductPerDay = 12000,
    this.partialDayDeductPercent = 50,
  });

  final bool lateDeductsPay;
  final bool overtimeAddsPay;
  final bool absenceDeductsPay;
  final bool partialDayDeductsPay;

  /// Списание за минуту опоздания, ₸.
  final int lateDeductPerMinute;

  /// Доплата за час переработки, ₸.
  final int overtimeBonusPerHour;

  /// Списание за пропуск дня, ₸.
  final int absenceDeductPerDay;

  /// Списание за неполный день, % от дневной ставки.
  final int partialDayDeductPercent;

  AttendancePayrollRules copyWith({
    bool? lateDeductsPay,
    bool? overtimeAddsPay,
    bool? absenceDeductsPay,
    bool? partialDayDeductsPay,
    int? lateDeductPerMinute,
    int? overtimeBonusPerHour,
    int? absenceDeductPerDay,
    int? partialDayDeductPercent,
  }) {
    return AttendancePayrollRules(
      lateDeductsPay: lateDeductsPay ?? this.lateDeductsPay,
      overtimeAddsPay: overtimeAddsPay ?? this.overtimeAddsPay,
      absenceDeductsPay: absenceDeductsPay ?? this.absenceDeductsPay,
      partialDayDeductsPay: partialDayDeductsPay ?? this.partialDayDeductsPay,
      lateDeductPerMinute: lateDeductPerMinute ?? this.lateDeductPerMinute,
      overtimeBonusPerHour: overtimeBonusPerHour ?? this.overtimeBonusPerHour,
      absenceDeductPerDay: absenceDeductPerDay ?? this.absenceDeductPerDay,
      partialDayDeductPercent: partialDayDeductPercent ?? this.partialDayDeductPercent,
    );
  }

  String get summaryRu {
    final parts = <String>[];
    if (lateDeductsPay) parts.add('опоздания −');
    if (overtimeAddsPay) parts.add('переработка +');
    if (absenceDeductsPay) parts.add('пропуски −');
    if (partialDayDeductsPay) parts.add('неполный день −');
    if (parts.isEmpty) return 'Не влияет на ЗП';
    return parts.join(' · ');
  }
}

/// Строка начисления / списания в расчёте работника.
class AttendancePayrollLineItem {
  const AttendancePayrollLineItem({
    required this.label,
    required this.amount,
    required this.kind,
    this.detail,
  });

  final String label;

  /// Как посчитано: «50 ₸ × 90 мин» и т.п.
  final String? detail;
  final int amount;
  final AttendancePayrollLineKind kind;
}

enum AttendancePayrollLineKind {
  base,
  deduction,
  bonus,
}

/// Расчёт ЗП одного работника за период (mock).
class AttendanceWorkerPayroll {
  const AttendanceWorkerPayroll({
    required this.workerId,
    required this.displayName,
    required this.username,
    required this.baseSalary,
    required this.lines,
  });

  final String workerId;
  final String displayName;
  final String username;
  final int baseSalary;
  final List<AttendancePayrollLineItem> lines;

  int get totalDeductions => lines
      .where((e) => e.kind == AttendancePayrollLineKind.deduction)
      .fold(0, (sum, e) => sum + e.amount);

  int get totalBonuses => lines
      .where((e) => e.kind == AttendancePayrollLineKind.bonus)
      .fold(0, (sum, e) => sum + e.amount);

  int get netPay => baseSalary - totalDeductions + totalBonuses;
}

/// Сводка по команде за месяц.
class AttendancePayrollTeamSummary {
  const AttendancePayrollTeamSummary({
    required this.periodLabel,
    required this.workerCount,
    required this.totalBase,
    required this.totalDeductions,
    required this.totalBonuses,
  });

  final String periodLabel;
  final int workerCount;
  final int totalBase;
  final int totalDeductions;
  final int totalBonuses;

  int get netPay => totalBase - totalDeductions + totalBonuses;

  factory AttendancePayrollTeamSummary.fromRows({
    required String periodLabel,
    required List<AttendanceWorkerPayroll> rows,
  }) {
    return AttendancePayrollTeamSummary(
      periodLabel: periodLabel,
      workerCount: rows.length,
      totalBase: rows.fold(0, (s, r) => s + r.baseSalary),
      totalDeductions: rows.fold(0, (s, r) => s + r.totalDeductions),
      totalBonuses: rows.fold(0, (s, r) => s + r.totalBonuses),
    );
  }
}

String attendanceFormatMoney(int value) {
  final negative = value < 0;
  final abs = value.abs();
  final formatted = abs.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]} ',
  );
  return negative ? '−$formatted ₸' : '$formatted ₸';
}

String attendanceFormatMoneySigned(int value, {required bool isBonus}) {
  if (value == 0) return '0 ₸';
  final prefix = isBonus ? '+' : '−';
  return '$prefix${attendanceFormatMoney(value)}';
}
