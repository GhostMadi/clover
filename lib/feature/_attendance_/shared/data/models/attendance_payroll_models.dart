/// Правила влияния посещаемости на зарплату (хранятся на workplace, preview — RPC).
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
      partialDayDeductPercent:
          partialDayDeductPercent ?? this.partialDayDeductPercent,
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

  Map<String, dynamic> toJson() => {
    'late_deducts_pay': lateDeductsPay,
    'overtime_adds_pay': overtimeAddsPay,
    'absence_deducts_pay': absenceDeductsPay,
    'partial_day_deducts_pay': partialDayDeductsPay,
    'late_deduct_per_minute': lateDeductPerMinute,
    'overtime_bonus_per_hour': overtimeBonusPerHour,
    'absence_deduct_per_day': absenceDeductPerDay,
    'partial_day_deduct_percent': partialDayDeductPercent,
  };

  static AttendancePayrollRules fromJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) return const AttendancePayrollRules();
    return AttendancePayrollRules(
      lateDeductsPay: json['late_deducts_pay'] as bool? ?? false,
      overtimeAddsPay: json['overtime_adds_pay'] as bool? ?? false,
      absenceDeductsPay: json['absence_deducts_pay'] as bool? ?? true,
      partialDayDeductsPay: json['partial_day_deducts_pay'] as bool? ?? false,
      lateDeductPerMinute:
          (json['late_deduct_per_minute'] as num?)?.toInt() ?? 50,
      overtimeBonusPerHour:
          (json['overtime_bonus_per_hour'] as num?)?.toInt() ?? 1500,
      absenceDeductPerDay:
          (json['absence_deduct_per_day'] as num?)?.toInt() ?? 12000,
      partialDayDeductPercent:
          (json['partial_day_deduct_percent'] as num?)?.toInt() ?? 50,
    );
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

  factory AttendancePayrollLineItem.fromJson(Map<String, dynamic> json) {
    final kind = AttendancePayrollLineKind.fromKey(json['kind']?.toString());
    final rawAmount = (json['amount'] as num?)?.toInt() ?? 0;
    final code = json['label']?.toString() ?? '';
    final detailRaw = json['detail']?.toString();
    return AttendancePayrollLineItem(
      label: _payrollLineLabelRu(code),
      detail: detailRaw == null ? null : _payrollLineDetailRu(code, detailRaw),
      amount: kind == AttendancePayrollLineKind.deduction
          ? rawAmount.abs()
          : rawAmount,
      kind: kind,
    );
  }
}

String _payrollLineLabelRu(String code) => switch (code) {
  'late' => 'Опоздания',
  'missed_shift' => 'Пропуск смены',
  'absence_recorded' => 'Отсутствие оформлено',
  'partial_day' => 'Неполный день',
  'overtime_approved' => 'Переработка (утверждено)',
  // Legacy RU from older RPC / offline
  'Опоздания' ||
  'Пропуск смены' ||
  'Отсутствие оформлено' ||
  'Неполный день' ||
  'Переработка (утверждено)' => code,
  _ => code,
};

String _payrollLineDetailRu(String code, String detail) {
  final parts = detail.split('|');
  switch (code) {
    case 'late':
      if (parts.length >= 3) {
        return '${parts[0]} ₸ × ${parts[1]} мин · ${parts[2]} дн.';
      }
    case 'missed_shift':
      if (parts.length >= 2) {
        return '${parts[0]} ₸ × ${parts[1]} дн.';
      }
    case 'absence_recorded':
      final kinds = detail
          .split(',')
          .map((k) => switch (k.trim()) {
            'day_off' => 'Выходной',
            'vacation' => 'Отпуск',
            'sick' => 'Больничный',
            final other => other,
          })
          .where((e) => e.isNotEmpty)
          .join(', ');
      return kinds.isEmpty ? detail : '$kinds — не штраф за пропуск';
    case 'partial_day':
      if (parts.length >= 2) {
        return '${parts[0]}% от дневной ставки · ${parts[1]}';
      }
    case 'overtime_approved':
      if (parts.length >= 2) {
        return '${parts[0]} ₸ × ${parts[1]} ч';
      }
  }
  return detail;
}

String attendancePayrollPeriodLabelRu(String periodKey) {
  final m = RegExp(r'^(\d{4})-(\d{2})$').firstMatch(periodKey.trim());
  if (m == null) return periodKey;
  const months = [
    'Январь',
    'Февраль',
    'Март',
    'Апрель',
    'Май',
    'Июнь',
    'Июль',
    'Август',
    'Сентябрь',
    'Октябрь',
    'Ноябрь',
    'Декабрь',
  ];
  final month = int.tryParse(m.group(2)!) ?? 0;
  if (month < 1 || month > 12) return periodKey;
  return '${months[month - 1]} ${m.group(1)}';
}

enum AttendancePayrollLineKind {
  base,
  deduction,
  bonus;

  static AttendancePayrollLineKind fromKey(String? value) => switch (value) {
    'deduction' => AttendancePayrollLineKind.deduction,
    'bonus' => AttendancePayrollLineKind.bonus,
    _ => AttendancePayrollLineKind.base,
  };
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

  factory AttendanceWorkerPayroll.fromJson(Map<String, dynamic> json) {
    final linesRaw = json['lines'] as List? ?? const [];
    return AttendanceWorkerPayroll(
      workerId: json['worker_id']?.toString() ?? '',
      displayName: json['display_name']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      baseSalary: (json['base_salary'] as num?)?.toInt() ?? 0,
      lines: [
        for (final raw in linesRaw)
          if (raw is Map)
            AttendancePayrollLineItem.fromJson(Map<String, dynamic>.from(raw)),
      ],
    );
  }

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
    this.rows = const [],
  });

  final String periodLabel;
  final int workerCount;
  final int totalBase;
  final int totalDeductions;
  final int totalBonuses;
  final List<AttendanceWorkerPayroll> rows;

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
      rows: rows,
    );
  }

  factory AttendancePayrollTeamSummary.fromJson(Map<String, dynamic> json) {
    final workersRaw = json['workers'] as List? ?? const [];
    final rows = [
      for (final raw in workersRaw)
        if (raw is Map)
          AttendanceWorkerPayroll.fromJson(Map<String, dynamic>.from(raw)),
    ];
    final teamRaw = json['team'];
    final team = teamRaw is Map
        ? Map<String, dynamic>.from(teamRaw)
        : const <String, dynamic>{};
    return AttendancePayrollTeamSummary(
      periodLabel: attendancePayrollPeriodLabelRu(
        json['period_label']?.toString() ?? '',
      ),
      workerCount: rows.length,
      totalBase:
          (team['base_total'] as num?)?.toInt() ??
          rows.fold(0, (sum, row) => sum + row.baseSalary),
      totalDeductions:
          (team['deductions_total'] as num?)?.toInt() ??
          rows.fold(0, (sum, row) => sum + row.totalDeductions),
      totalBonuses:
          (team['bonuses_total'] as num?)?.toInt() ??
          rows.fold(0, (sum, row) => sum + row.totalBonuses),
      rows: rows,
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
