import 'package:clover/feature/_booking_/shared/data/booking_status_display.dart';
import 'package:clover/feature/_booking_/shared/data/models/booking_status.dart';

class BookingListItem {
  const BookingListItem({
    required this.id,
    required this.clientName,
    required this.serviceTitle,
    required this.startsAt,
    required this.status,
    this.clientId,
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
  final String? clientId;
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

  BookingListItem copyWith({BookingStatus? status, String? clientId}) {
    return BookingListItem(
      id: id,
      clientId: clientId ?? this.clientId,
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

  factory BookingListItem.fromJson(Map<String, dynamic> json) {
    return BookingListItem(
      id: json['id']?.toString() ?? '',
      clientId: json['client_id']?.toString(),
      clientName: json['client_name']?.toString() ?? '',
      serviceTitle: json['service_title']?.toString() ?? '',
      startsAt: json['starts_at']?.toString() ?? '',
      status: BookingStatus.fromDbOrPending(json['status']?.toString()),
      clientPhone: json['client_phone']?.toString(),
      clientUsername: json['client_username']?.toString(),
      serviceEmoji: json['service_emoji']?.toString() ?? '💈',
      durationMinutes: (json['duration_minutes'] as num?)?.toInt() ?? 30,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      executorName: json['executor_name']?.toString(),
      notes: json['notes']?.toString(),
      participantsCount: (json['participants_count'] as num?)?.toInt() ?? 1,
      createdAt: json['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'client_id': clientId,
        'client_name': clientName,
        'service_title': serviceTitle,
        'starts_at': startsAt,
        'status': status.dbValue,
        'client_phone': clientPhone,
        'client_username': clientUsername,
        'service_emoji': serviceEmoji,
        'duration_minutes': durationMinutes,
        'price': price,
        'executor_name': executorName,
        'notes': notes,
        'participants_count': participantsCount,
        'created_at': createdAt,
      };
}
