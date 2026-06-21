/// Статус записи (`public.booking_status`).
enum BookingStatus {
  pending('pending'),
  confirmed('confirmed'),
  clientArrived('client_arrived'),
  inProgress('in_progress'),
  completed('completed'),
  cancelled('cancelled');

  const BookingStatus(this.dbValue);

  final String dbValue;

  static BookingStatus? fromDb(String? raw) {
    final v = raw?.trim();
    if (v == null || v.isEmpty) return null;
    for (final item in BookingStatus.values) {
      if (item.dbValue == v) return item;
    }
    return null;
  }

  static BookingStatus fromDbOrPending(String? raw) => fromDb(raw) ?? BookingStatus.pending;

  String get label => switch (this) {
        BookingStatus.pending => 'Ожидает',
        BookingStatus.confirmed => 'Подтверждена',
        BookingStatus.clientArrived => 'Клиент пришёл',
        BookingStatus.inProgress => 'Оказывается',
        BookingStatus.completed => 'Оказана',
        BookingStatus.cancelled => 'Отменена',
      };

  bool get isActiveVisit =>
      this == BookingStatus.pending ||
      this == BookingStatus.confirmed ||
      this == BookingStatus.clientArrived ||
      this == BookingStatus.inProgress;
}
