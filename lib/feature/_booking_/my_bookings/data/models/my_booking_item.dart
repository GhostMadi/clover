import 'package:clover/feature/_booking_/shared/data/booking_status_display.dart';
import 'package:clover/feature/_booking_/shared/data/models/booking_status.dart';

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
  final BookingStatus status;
  final String? notes;
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

  bool get showCancelAction =>
      status == BookingStatus.pending || status == BookingStatus.confirmed;

  bool get canClientCancel {
    if (!showCancelAction) return false;
    final start = startsAtDate;
    if (start == null) return true;
    return start.isAfter(DateTime.now());
  }

  factory MyBookingItem.fromJson(Map<String, dynamic> json) {
    return MyBookingItem(
      id: json['id']?.toString() ?? '',
      hostId: json['host_id']?.toString() ?? '',
      hostDisplayName: json['host_display_name']?.toString() ?? '',
      hostUsername: json['host_username']?.toString(),
      serviceTitle: json['service_title']?.toString() ?? '',
      serviceEmoji: json['service_emoji']?.toString() ?? '💈',
      durationMinutes: (json['duration_minutes'] as num?)?.toInt() ?? 30,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      executorName: json['executor_name']?.toString(),
      startsAt: json['starts_at']?.toString() ?? '',
      status: BookingStatus.fromDbOrPending(json['status']?.toString()),
      notes: json['notes']?.toString(),
      createdAt: json['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'host_id': hostId,
        'host_display_name': hostDisplayName,
        'host_username': hostUsername,
        'service_title': serviceTitle,
        'service_emoji': serviceEmoji,
        'duration_minutes': durationMinutes,
        'price': price,
        'executor_name': executorName,
        'starts_at': startsAt,
        'status': status.dbValue,
        'notes': notes,
        'created_at': createdAt,
      };
}
