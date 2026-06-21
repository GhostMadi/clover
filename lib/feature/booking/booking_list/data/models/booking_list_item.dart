import 'package:clover/feature/booking/shared/data/booking_status_display.dart';
import 'package:clover/feature/booking/shared/data/models/booking_status.dart';

class BookingListItem {
  const BookingListItem({
    required this.id,
    required this.clientName,
    required this.serviceTitle,
    required this.startsAt,
    required this.status,
    this.clientPhone,
    this.clientUsername,
    this.serviceEmoji = '💈',
    this.durationMinutes = 30,
    this.price = 0,
    this.executorName,
    this.notes,
    this.participantsCount = 1,
    this.createdAt,
  });

  final String id;
  final String clientName;
  final String serviceTitle;
  final String startsAt;
  final BookingStatus status;
  final String? clientPhone;
  final String? clientUsername;
  final String serviceEmoji;
  final int durationMinutes;
  final double price;
  final String? executorName;
  final String? notes;
  final int participantsCount;
  final String? createdAt;

  DateTime? get startsAtDate {
    final parsed = DateTime.tryParse(startsAt);
    return parsed?.toLocal();
  }

  DateTime? get createdAtDate => createdAt == null ? null : DateTime.tryParse(createdAt!);

  DateTime? get endsAtDate {
    final start = startsAtDate;
    if (start == null) return null;
    return start.add(Duration(minutes: durationMinutes));
  }

  String get statusLabel => BookingStatusDisplay.label(status, endsAt: endsAtDate);

  bool get isVisitUnmarked => BookingStatusDisplay.isUnmarked(status, endsAtDate);

  BookingListItem copyWith({BookingStatus? status}) {
    return BookingListItem(
      id: id,
      clientName: clientName,
      serviceTitle: serviceTitle,
      startsAt: startsAt,
      status: status ?? this.status,
      clientPhone: clientPhone,
      clientUsername: clientUsername,
      serviceEmoji: serviceEmoji,
      durationMinutes: durationMinutes,
      price: price,
      executorName: executorName,
      notes: notes,
      participantsCount: participantsCount,
      createdAt: createdAt,
    );
  }

  String get priceLabel {
    if (price == price.roundToDouble()) {
      return '${price.toInt()} ₸';
    }
    return '${price.toStringAsFixed(2)} ₸';
  }

  String get clientUsernameLabel {
    final raw = clientUsername?.trim();
    if (raw == null || raw.isEmpty) return '';
    return raw.startsWith('@') ? raw : '@$raw';
  }
}
