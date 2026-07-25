class BookingListDateRange {
  const BookingListDateRange({required this.start, required this.end});

  final DateTime start;
  final DateTime end;

  static DateTime _day(DateTime value) => DateTime(value.year, value.month, value.day);

  static DateTime _today() => _day(DateTime.now());

  /// Понедельник текущей недели (ISO).
  static DateTime _mondayOf(DateTime day) => day.subtract(Duration(days: day.weekday - 1));

  factory BookingListDateRange.today() {
    final day = _today();
    return BookingListDateRange(start: day, end: day);
  }

  factory BookingListDateRange.tomorrow() {
    final day = _today().add(const Duration(days: 1));
    return BookingListDateRange(start: day, end: day);
  }

  /// С сегодня до воскресенья текущей недели.
  factory BookingListDateRange.thisWeek() {
    final today = _today();
    final sunday = _mondayOf(today).add(const Duration(days: 6));
    return BookingListDateRange(start: today, end: sunday);
  }

  /// Следующая полная неделя (пн–вс).
  factory BookingListDateRange.nextWeek() {
    final today = _today();
    final nextMonday = _mondayOf(today).add(const Duration(days: 7));
    final nextSunday = nextMonday.add(const Duration(days: 6));
    return BookingListDateRange(start: nextMonday, end: nextSunday);
  }

  /// С сегодня до конца текущего месяца.
  factory BookingListDateRange.thisMonth() {
    final today = _today();
    final end = DateTime(today.year, today.month + 1, 0);
    return BookingListDateRange(start: today, end: end);
  }

  /// Весь следующий календарный месяц.
  factory BookingListDateRange.nextMonth() {
    final today = _today();
    final start = DateTime(today.year, today.month + 1, 1);
    final end = DateTime(today.year, today.month + 2, 0);
    return BookingListDateRange(start: start, end: end);
  }

  /// Прошлые и предстоящие записи клиента (≈ месяц назад — 2 месяца вперёд).
  factory BookingListDateRange.recentAndUpcoming() {
    final today = _today();
    return BookingListDateRange(
      start: today.subtract(const Duration(days: 30)),
      end: today.add(const Duration(days: 60)),
    );
  }

  /// Host inbox: забытые/история + ближайшие записи.
  factory BookingListDateRange.hostInbox() {
    final today = _today();
    return BookingListDateRange(
      start: today.subtract(const Duration(days: 45)),
      end: today.add(const Duration(days: 60)),
    );
  }

  bool sameDayRange(BookingListDateRange other) {
    return _day(start) == _day(other.start) && _day(end) == _day(other.end);
  }

  bool contains(DateTime dateTime) {
    final day = _day(dateTime);
    final from = _day(start);
    final to = _day(end);
    return !day.isBefore(from) && !day.isAfter(to);
  }

  String get label {
    const months = [
      'янв',
      'фев',
      'мар',
      'апр',
      'май',
      'июн',
      'июл',
      'авг',
      'сен',
      'окт',
      'ноя',
      'дек',
    ];

    final from = _day(start);
    final to = _day(end);
    final today = _today();

    if (sameDayRange(BookingListDateRange.today())) return 'Сегодня';
    if (sameDayRange(BookingListDateRange.tomorrow())) return 'Завтра';
    if (sameDayRange(BookingListDateRange.thisWeek())) return 'Эта неделя';
    if (sameDayRange(BookingListDateRange.nextWeek())) return 'След. неделя';
    if (sameDayRange(BookingListDateRange.thisMonth())) return 'Этот месяц';
    if (sameDayRange(BookingListDateRange.nextMonth())) return 'След. месяц';
    if (sameDayRange(BookingListDateRange.hostInbox())) return 'Все записи';
    if (sameDayRange(BookingListDateRange.recentAndUpcoming())) return 'Недавние';

    if (from == to) {
      if (from == today) return 'Сегодня';
      return '${from.day} ${months[from.month - 1]}';
    }

    final startLabel = '${from.day} ${months[from.month - 1]}';
    final endLabel = '${to.day} ${months[to.month - 1]}';
    if (from.year == to.year) {
      return '$startLabel — $endLabel ${from.year}';
    }
    return '$startLabel ${from.year} — $endLabel ${to.year}';
  }
}
