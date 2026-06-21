/// Горизонт бронирования (`public.booking_horizon_kind`).
enum BookingHorizonKind {
  daysAhead('days_ahead'),
  untilDate('until_date');

  const BookingHorizonKind(this.dbValue);

  final String dbValue;

  static BookingHorizonKind? fromDb(String? raw) {
    final v = raw?.trim();
    if (v == null || v.isEmpty) return null;
    for (final item in BookingHorizonKind.values) {
      if (item.dbValue == v) return item;
    }
    return null;
  }

  static BookingHorizonKind fromDbOrDefault(String? raw) =>
      fromDb(raw) ?? BookingHorizonKind.daysAhead;
}
