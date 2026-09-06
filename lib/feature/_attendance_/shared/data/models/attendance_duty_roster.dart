/// Дежурство: очередь работников по рабочим дням.
class AttendanceDutyRoster {
  const AttendanceDutyRoster({
    this.workerIds = const [],
    this.workingWeekdays = const {1, 2, 3, 4, 5},
    this.startDate,
  });

  final List<String> workerIds;
  final Set<int> workingWeekdays;
  final DateTime? startDate;

  bool get isConfigured => workerIds.isNotEmpty;

  AttendanceDutyRoster copyWith({
    List<String>? workerIds,
    Set<int>? workingWeekdays,
    DateTime? startDate,
    bool clearStartDate = false,
  }) {
    return AttendanceDutyRoster(
      workerIds: workerIds ?? this.workerIds,
      workingWeekdays: workingWeekdays ?? this.workingWeekdays,
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
    );
  }

  List<String> onDutyFor(DateTime day) {
    if (workerIds.isEmpty || !workingWeekdays.contains(day.weekday)) {
      return const [];
    }
    final anchor = _dayKey(startDate ?? DateTime(day.year, day.month, 1));
    final target = _dayKey(day);
    var index = 0;
    var cursor = anchor;
    while (cursor.isBefore(target)) {
      if (workingWeekdays.contains(cursor.weekday)) {
        index++;
      }
      cursor = cursor.add(const Duration(days: 1));
    }
    return [workerIds[index % workerIds.length]];
  }

  static DateTime _dayKey(DateTime value) => DateTime(value.year, value.month, value.day);

  Map<String, dynamic> toJson() => {
        'worker_ids': workerIds,
        'working_weekdays': workingWeekdays.toList()..sort(),
        if (startDate != null)
          'start_date':
              '${startDate!.year.toString().padLeft(4, '0')}-'
              '${startDate!.month.toString().padLeft(2, '0')}-'
              '${startDate!.day.toString().padLeft(2, '0')}',
      };

  static AttendanceDutyRoster fromJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) return const AttendanceDutyRoster();
    final idsRaw = json['worker_ids'];
    final daysRaw = json['working_weekdays'];
    final ids = idsRaw is List
        ? [for (final e in idsRaw) e.toString()].where((e) => e.isNotEmpty).toList(growable: false)
        : const <String>[];
    final days = daysRaw is List
        ? {for (final e in daysRaw) if (e is num) e.toInt()}
        : const {1, 2, 3, 4, 5};
    final startRaw = json['start_date']?.toString();
    final start = startRaw == null || startRaw.isEmpty ? null : DateTime.tryParse(startRaw);
    return AttendanceDutyRoster(
      workerIds: ids,
      workingWeekdays: days.isEmpty ? const {1, 2, 3, 4, 5} : days,
      startDate: start == null ? null : DateTime(start.year, start.month, start.day),
    );
  }
}

extension AttendanceWeekdayX on int {
  String get labelRuShort => switch (this) {
        1 => 'Пн',
        2 => 'Вт',
        3 => 'Ср',
        4 => 'Чт',
        5 => 'Пт',
        6 => 'Сб',
        7 => 'Вс',
        _ => '?',
      };
}
