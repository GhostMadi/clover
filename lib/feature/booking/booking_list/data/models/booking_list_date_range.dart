class BookingListDateRange {
  const BookingListDateRange({required this.start, required this.end});

  final DateTime start;
  final DateTime end;

  factory BookingListDateRange.today() {
    final now = DateTime.now();
    final day = DateTime(now.year, now.month, now.day);
    return BookingListDateRange(start: day, end: day);
  }

  /// Прошлые и предстоящие записи клиента (≈ месяц назад — 2 месяца вперёд).
  factory BookingListDateRange.recentAndUpcoming() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return BookingListDateRange(
      start: today.subtract(const Duration(days: 30)),
      end: today.add(const Duration(days: 60)),
    );
  }

  bool contains(DateTime dateTime) {
    final day = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final from = DateTime(start.year, start.month, start.day);
    final to = DateTime(end.year, end.month, end.day);
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

    final from = DateTime(start.year, start.month, start.day);
    final to = DateTime(end.year, end.month, end.day);

    if (from == to) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
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
