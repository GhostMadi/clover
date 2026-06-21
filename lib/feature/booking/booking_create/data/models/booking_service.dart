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

  String? get executorId => executorIds.isEmpty ? null : executorIds.first;

  String get displaySubtitle {
    final parts = <String>[
      '$durationMinutes мин',
      if (maxParticipants > 1) 'до $maxParticipants чел.',
      if (bufferAfterMinutes > 0) 'буфер $bufferAfterMinutes мин',
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
    );
  }
}
