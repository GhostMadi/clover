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
