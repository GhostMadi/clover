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
    this.serviceId,
    this.serviceEmoji = '💈',
    this.durationMinutes = 30,
    this.price = 0,
    this.staffId,
    this.executorName,
    this.notes,
    this.createdAt,
    this.clientCancelHoursBefore = 0,
  });

  final String id;
  final String hostId;
  final String hostDisplayName;
  final String? hostUsername;
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
  final int clientCancelHoursBefore;

  DateTime? get startsAtDate {
    final parsed = DateTime.tryParse(startsAt);
    return parsed?.toLocal();
  }

  DateTime? get createdAtDate =>
      createdAt == null ? null : DateTime.tryParse(createdAt!);

  DateTime? get endsAtDate {
    final start = startsAtDate;
    if (start == null) return null;
    return start.add(Duration(minutes: durationMinutes));
  }

  String get statusLabel =>
      BookingStatusDisplay.label(status, endsAt: endsAtDate);

  bool get isVisitUnmarked =>
      BookingStatusDisplay.isUnmarked(status, endsAtDate);

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
    final deadline = start.subtract(Duration(hours: clientCancelHoursBefore));
    return DateTime.now().isBefore(deadline);
  }

  bool get canClientReschedule {
    if (!showCancelAction) return false;
    final sid = staffId?.trim();
    if (sid == null || sid.isEmpty) return false;
    return canClientCancel;
  }

  MyBookingItem copyWith({
    String? startsAt,
    BookingStatus? status,
    String? serviceId,
    String? staffId,
    int? clientCancelHoursBefore,
  }) {
    return MyBookingItem(
      id: id,
      hostId: hostId,
      hostDisplayName: hostDisplayName,
      hostUsername: hostUsername,
      serviceId: serviceId ?? this.serviceId,
      serviceTitle: serviceTitle,
      serviceEmoji: serviceEmoji,
      durationMinutes: durationMinutes,
      price: price,
      staffId: staffId ?? this.staffId,
      executorName: executorName,
      startsAt: startsAt ?? this.startsAt,
      status: status ?? this.status,
      notes: notes,
      createdAt: createdAt,
      clientCancelHoursBefore:
          clientCancelHoursBefore ?? this.clientCancelHoursBefore,
    );
  }

  factory MyBookingItem.fromJson(Map<String, dynamic> json) {
    return MyBookingItem(
      id: json['id']?.toString() ?? '',
      hostId: json['host_id']?.toString() ?? '',
      hostDisplayName: json['host_display_name']?.toString() ?? '',
      hostUsername: json['host_username']?.toString(),
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
      clientCancelHoursBefore:
          (json['client_cancel_hours_before'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'host_id': hostId,
    'host_display_name': hostDisplayName,
    'host_username': hostUsername,
    'service_id': serviceId,
    'service_title': serviceTitle,
    'service_emoji': serviceEmoji,
    'duration_minutes': durationMinutes,
    'price': price,
    'staff_id': staffId,
    'executor_name': executorName,
    'starts_at': startsAt,
    'status': status.dbValue,
    'notes': notes,
    'created_at': createdAt,
    'client_cancel_hours_before': clientCancelHoursBefore,
  };
}
