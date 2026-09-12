/// Услуга для записи (например «Стрижка мужская»).
class BookingService {
  const BookingService({
    required this.id,
    required this.title,
    required this.durationMinutes,
    required this.emojiText,
    required this.price,
    required this.maxParticipants,
    required this.bufferAfterMinutes,
    this.description,
    this.executorIds = const [],
    this.isActive = true,
    this.bonusPayPercent = 0,
    this.bonusEarnAmount = 0,
    this.pointId,
  });

  final String id;
  final String title;
  final int durationMinutes;
  final String emojiText;
  final double price;
  final int maxParticipants;
  final int bufferAfterMinutes;
  final String? description;
  final List<String> executorIds;
  final bool isActive;

  /// Доля стоимости услуги, которую можно оплатить бонусами (0–100%).
  final int bonusPayPercent;

  /// Сколько бонусов клиент получит за завершённый визит.
  final int bonusEarnAmount;

  /// Точка хозяина (`booking_points`); null — legacy / ещё не привязана.
  final String? pointId;

  String? get executorId => executorIds.isEmpty ? null : executorIds.first;

  String get displaySubtitle {
    final parts = <String>[
      '$durationMinutes мин',
      if (maxParticipants > 1) 'до $maxParticipants чел.',
      if (bufferAfterMinutes > 0) 'буфер $bufferAfterMinutes мин',
      if (bonusPayPercent > 0) 'оплата до $bonusPayPercent%',
      if (bonusEarnAmount > 0) '+$bonusEarnAmount бонусов',
      if (!isActive) 'неактивна',
    ];
    return parts.join(' · ');
  }

  String get priceLabel {
    if (price == price.roundToDouble()) {
      return '${price.toInt()} ₸';
    }
    return '${price.toStringAsFixed(2)} ₸';
  }

  BookingService copyWith({
    String? title,
    int? durationMinutes,
    String? emojiText,
    double? price,
    int? maxParticipants,
    int? bufferAfterMinutes,
    String? description,
    bool clearDescription = false,
    List<String>? executorIds,
    bool? isActive,
    int? bonusPayPercent,
    int? bonusEarnAmount,
    String? pointId,
    bool clearPointId = false,
  }) {
    return BookingService(
      id: id,
      title: title ?? this.title,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      emojiText: emojiText ?? this.emojiText,
      price: price ?? this.price,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      bufferAfterMinutes: bufferAfterMinutes ?? this.bufferAfterMinutes,
      description: clearDescription ? null : (description ?? this.description),
      executorIds: executorIds ?? this.executorIds,
      isActive: isActive ?? this.isActive,
      bonusPayPercent: bonusPayPercent ?? this.bonusPayPercent,
      bonusEarnAmount: bonusEarnAmount ?? this.bonusEarnAmount,
      pointId: clearPointId ? null : (pointId ?? this.pointId),
    );
  }

  factory BookingService.fromJson(Map<String, dynamic> json) {
    final rawIds = json['executor_ids'];
    final executorIds = <String>[];
    if (rawIds is List) {
      for (final id in rawIds) {
        final value = id?.toString().trim();
        if (value != null && value.isNotEmpty) executorIds.add(value);
      }
    }

    return BookingService(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      durationMinutes: (json['duration_minutes'] as num?)?.toInt() ?? 30,
      emojiText: json['emoji_text']?.toString() ?? '💈',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      maxParticipants: (json['max_participants'] as num?)?.toInt() ?? 1,
      bufferAfterMinutes: (json['buffer_after_minutes'] as num?)?.toInt() ?? 0,
      description: json['description']?.toString(),
      executorIds: executorIds,
      isActive: json['is_active'] == true || json['is_active'] == null,
      bonusPayPercent: (json['bonus_pay_percent'] as num?)?.toInt() ?? 0,
      bonusEarnAmount: (json['bonus_earn_amount'] as num?)?.toInt() ?? 0,
      pointId: json['point_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'duration_minutes': durationMinutes,
        'emoji_text': emojiText,
        'price': price,
        'max_participants': maxParticipants,
        'buffer_after_minutes': bufferAfterMinutes,
        'description': description,
        'executor_ids': executorIds,
        'is_active': isActive,
        'bonus_pay_percent': bonusPayPercent,
        'bonus_earn_amount': bonusEarnAmount,
        'point_id': pointId,
      };
}
