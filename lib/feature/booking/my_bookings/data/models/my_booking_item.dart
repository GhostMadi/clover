import 'package:clover/feature/booking/booking_list/data/models/booking_list_item.dart';

class MyBookingItem {
  const MyBookingItem({
    required this.id,
    required this.hostId,
    required this.hostDisplayName,
    required this.serviceTitle,
    required this.startsAt,
    required this.status,
    this.hostUsername,
    this.serviceEmoji = '💈',
    this.durationMinutes = 30,
    this.price = 0,
    this.executorName,
    this.notes,
    this.createdAt,
  });

  final String id;
  final String hostId;
  final String hostDisplayName;
  final String? hostUsername;
  final String serviceTitle;
  final String serviceEmoji;
  final int durationMinutes;
  final double price;
  final String? executorName;
  final String startsAt;
  final BookingListStatus status;
  final String? notes;
  final String? createdAt;

  DateTime? get startsAtDate => DateTime.tryParse(startsAt);

  DateTime? get createdAtDate => createdAt == null ? null : DateTime.tryParse(createdAt!);

  DateTime? get endsAtDate {
    final start = startsAtDate;
    if (start == null) return null;
    return start.add(Duration(minutes: durationMinutes));
  }

  String get statusLabel => switch (status) {
        BookingListStatus.pending => 'Ожидает',
        BookingListStatus.confirmed => 'Подтверждена',
        BookingListStatus.completed => 'Завершена',
        BookingListStatus.cancelled => 'Отменена',
      };

  String get priceLabel {
    if (price == price.roundToDouble()) {
      return '${price.toInt()} ₸';
    }
    return '${price.toStringAsFixed(2)} ₸';
  }

  String get hostUsernameLabel {
    final raw = hostUsername?.trim();
    if (raw == null || raw.isEmpty) return '';
    return raw.startsWith('@') ? raw : '@$raw';
  }

  bool get isPast {
    final end = endsAtDate;
    if (end == null) return false;
    return end.isBefore(DateTime.now());
  }
}
