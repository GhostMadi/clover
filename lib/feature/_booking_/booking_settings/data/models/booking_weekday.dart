/// День недели (как в [DateTime.weekday]: 1 = понедельник, 7 = воскресенье).
enum BookingWeekday {
  monday(1, 'Пн', 'понедельник'),
  tuesday(2, 'Вт', 'вторник'),
  wednesday(3, 'Ср', 'среда'),
  thursday(4, 'Чт', 'четверг'),
  friday(5, 'Пт', 'пятница'),
  saturday(6, 'Сб', 'суббота'),
  sunday(7, 'Вс', 'воскресенье');

  const BookingWeekday(this.isoWeekday, this.shortLabel, this.fullLabel);

  final int isoWeekday;
  final String shortLabel;
  final String fullLabel;

  static BookingWeekday? fromIso(int weekday) {
    for (final day in BookingWeekday.values) {
      if (day.isoWeekday == weekday) return day;
    }
    return null;
  }

  static String joinedShortLabels(Set<int> weekdays) {
    if (weekdays.isEmpty) return 'нет';
    final sorted = weekdays.toList()..sort();
    return [
      for (final w in sorted)
        if (fromIso(w) != null) fromIso(w)!.shortLabel,
    ].join(', ');
  }
}
