/// Статус дня в аналитике посещаемости.
enum AttendanceDayStatus {
  full,
  late,
  partial,
  absent,
  /// Оформленное отсутствие (отпуск / больничный / выходной) — не пропуск.
  excused,
  off,
}

extension AttendanceDayStatusX on AttendanceDayStatus {
  String get labelRu => switch (this) {
        AttendanceDayStatus.full => 'Полная смена',
        AttendanceDayStatus.late => 'Опоздание',
        AttendanceDayStatus.partial => 'Неполная',
        AttendanceDayStatus.absent => 'Пропуск',
        AttendanceDayStatus.excused => 'Оформлено',
        AttendanceDayStatus.off => 'Выходной',
      };

  /// Короткая подпись для списков и календаря.
  String get shortLabelRu => switch (this) {
        AttendanceDayStatus.full => 'На смене',
        AttendanceDayStatus.late => 'Опоздал',
        AttendanceDayStatus.partial => 'Не завершил',
        AttendanceDayStatus.absent => 'Не пришёл',
        AttendanceDayStatus.excused => 'Отсутствие',
        AttendanceDayStatus.off => 'Выходной',
      };
}

/// Одна отметка внутри дня.
class AttendanceDayPunch {
  const AttendanceDayPunch({required this.timeLabel, required this.label});

  final String timeLabel;
  final String label;
}

/// День работника.
class AttendanceWorkerDayRecord {
  const AttendanceWorkerDayRecord({
    required this.date,
    required this.status,
    required this.totalMinutes,
    this.punches = const [],
  });

  final DateTime date;
  final AttendanceDayStatus status;
  final int totalMinutes;
  final List<AttendanceDayPunch> punches;

  String get totalLabel {
    if (totalMinutes <= 0) return '—';
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    if (m == 0) return '${h}ч';
    return '${h}ч ${m}м';
  }

  /// Был ли хотя бы один punch в этот день.
  bool get hasPunches => punches.isNotEmpty;

  /// Рабочий день (не выходной и не оформленное отсутствие).
  bool get isWorkday =>
      status != AttendanceDayStatus.off && status != AttendanceDayStatus.excused;

  AttendanceDayPunch? get firstArrival {
    for (final p in punches) {
      if (p.label == 'Пришёл') return p;
    }
    return punches.isNotEmpty ? punches.first : null;
  }

  AttendanceDayPunch? get lastDeparture {
    AttendanceDayPunch? last;
    for (final p in punches) {
      if (p.label == 'Ушёл') last = p;
    }
    return last;
  }

  /// Крупный заголовок для UI: отметился или нет.
  String get presenceHeadline => switch (status) {
        AttendanceDayStatus.full => 'Отметился',
        AttendanceDayStatus.late => 'Отметился с опозданием',
        AttendanceDayStatus.partial => 'Отметился не полностью',
        AttendanceDayStatus.absent => 'Не отметился',
        AttendanceDayStatus.excused => 'Отсутствие оформлено',
        AttendanceDayStatus.off => 'Выходной',
      };

  /// Одна строка: пришёл / ушёл / пропуск.
  String get presenceSummary {
    if (status == AttendanceDayStatus.off) return 'Рабочий день не назначен';
    if (status == AttendanceDayStatus.excused) {
      return 'Не считается пропуском в аналитике и зарплате';
    }
    if (status == AttendanceDayStatus.absent) return 'Отметок в этот день нет';

    final arrived = firstArrival;
    final left = lastDeparture;
    if (arrived == null && left == null) return 'Отметок нет';

    final parts = <String>[];
    if (arrived != null) parts.add('Пришёл ${arrived.timeLabel}');
    if (left != null) parts.add('Ушёл ${left.timeLabel}');
    if (parts.isEmpty && punches.isNotEmpty) {
      return '${punches.first.label} ${punches.first.timeLabel}';
    }
    return parts.join(' · ');
  }
}

/// Работник в аналитике.
class AttendanceAnalyticsWorker {
  const AttendanceAnalyticsWorker({
    required this.id,
    required this.displayName,
    required this.username,
    required this.totalMinutes,
    required this.daysWorked,
    required this.lateDays,
    required this.missedDays,
    required this.daysByKey,
  });

  final String id;
  final String displayName;
  final String username;
  final int totalMinutes;
  final int daysWorked;
  final int lateDays;
  final int missedDays;
  final Map<DateTime, AttendanceWorkerDayRecord> daysByKey;

  String get totalHoursLabel {
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    if (m == 0) return '${h}ч';
    return '${h}ч ${m}м';
  }

  double get hoursValue => totalMinutes / 60;
}

/// Сводка по компании за период.
class AttendanceAnalyticsOverview {
  const AttendanceAnalyticsOverview({
    required this.workers,
    required this.totalMinutes,
    required this.avgMinutesPerWorker,
    required this.lateDaysTotal,
    required this.missedDaysTotal,
  });

  final List<AttendanceAnalyticsWorker> workers;
  final int totalMinutes;
  final int avgMinutesPerWorker;
  final int lateDaysTotal;
  final int missedDaysTotal;

  String _fmt(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (m == 0) return '${h}ч';
    return '${h}ч ${m}м';
  }

  String get totalLabel => _fmt(totalMinutes);
  String get avgLabel => _fmt(avgMinutesPerWorker);
}
