import 'package:clover/feature/_booking_/shared/data/booking_status_display.dart';
import 'package:clover/feature/_booking_/shared/data/models/booking_status.dart';

/// Визит, где текущий пользователь — исполнитель (staff).
class BookingCalendarItem {
  const BookingCalendarItem({
    required this.id,
    required this.hostId,
    required this.hostDisplayName,
    required this.clientName,
    required this.serviceTitle,
    required this.startsAt,
    required this.status,
    this.hostUsername,
    this.clientId,
    this.clientUsername,
    this.serviceId,
    this.serviceEmoji = '💈',
    this.durationMinutes = 30,
    this.price = 0,
    this.staffId,
    this.executorName,
    this.notes,
    this.createdAt,
  });

  final String id;
  final String hostId;
  final String hostDisplayName;
  final String? hostUsername;
  final String? clientId;
  final String clientName;
  final String? clientUsername;
  final String? serviceId;
  final String serviceTitle;
  final String serviceEmoji;
  final int durationMinutes;
  final double price;
  final String? staffId;
  final String? executorName;
  final String startsAt;
  final BookingStatus status;
  final String? notes;
  final String? createdAt;

  DateTime? get startsAtDate {
    final parsed = DateTime.tryParse(startsAt);
    return parsed?.toLocal();
  }

  DateTime? get endsAtDate {
    final start = startsAtDate;
    if (start == null) return null;
    return start.add(Duration(minutes: durationMinutes));
  }

  String get statusLabel => BookingStatusDisplay.label(status, endsAt: endsAtDate);

  String get hostUsernameLabel {
    final raw = hostUsername?.trim();
    if (raw == null || raw.isEmpty) return '';
    return raw.startsWith('@') ? raw : '@$raw';
  }

  String get priceLabel {
    if (price == price.roundToDouble()) return '${price.toInt()} ₸';
    return '${price.toStringAsFixed(2)} ₸';
  }

  factory BookingCalendarItem.fromJson(Map<String, dynamic> json) {
    return BookingCalendarItem(
      id: json['id']?.toString() ?? '',
      hostId: json['host_id']?.toString() ?? '',
      hostDisplayName: json['host_display_name']?.toString() ?? '',
      hostUsername: json['host_username']?.toString(),
      clientId: json['client_id']?.toString(),
      clientName: json['client_name']?.toString() ?? '',
      clientUsername: json['client_username']?.toString(),
      serviceId: json['service_id']?.toString(),
      serviceTitle: json['service_title']?.toString() ?? '',
      serviceEmoji: json['service_emoji']?.toString() ?? '💈',
      durationMinutes: (json['duration_minutes'] as num?)?.toInt() ?? 30,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      staffId: json['staff_id']?.toString(),
      executorName: json['executor_name']?.toString(),
      startsAt: json['starts_at']?.toString() ?? '',
      status: BookingStatus.fromDbOrPending(json['status']?.toString()),
      notes: json['notes']?.toString(),
      createdAt: json['created_at']?.toString(),
    );
  }
}
