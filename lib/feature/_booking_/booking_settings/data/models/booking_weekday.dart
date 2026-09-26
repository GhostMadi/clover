import 'package:clover/core/locale/app_date_format.dart';

/// День недели (как в [DateTime.weekday]: 1 = понедельник, 7 = воскресенье).
enum BookingWeekday {
  monday(1),
  tuesday(2),
  wednesday(3),
  thursday(4),
  friday(5),
  saturday(6),
  sunday(7);

  const BookingWeekday(this.isoWeekday);

  final int isoWeekday;

  /// Sample date in 2024 with this ISO weekday (Jan 1 = Monday).
  DateTime get _sampleDate => DateTime(2024, 1, isoWeekday);

  String shortLabel([AppDateFormat? dates]) => (dates ?? AppDateFormat.current()).shortWeekday(_sampleDate);

  String fullLabel([AppDateFormat? dates]) => (dates ?? AppDateFormat.current()).fullWeekday(_sampleDate);

  static BookingWeekday? fromIso(int weekday) {
    for (final day in BookingWeekday.values) {
      if (day.isoWeekday == weekday) return day;
    }
    return null;
  }

  static String joinedShortLabels(Set<int> weekdays, [AppDateFormat? dates]) {
    if (weekdays.isEmpty) return '—';
    final fmt = dates ?? AppDateFormat.current();
    final sorted = weekdays.toList()..sort();
    return [
      for (final w in sorted)
        if (fromIso(w) != null) fromIso(w)!.shortLabel(fmt),
    ].join(', ');
  }
}
