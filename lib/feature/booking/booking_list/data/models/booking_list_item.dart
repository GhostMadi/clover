enum BookingListStatus {
  pending,
  confirmed,
  completed,
  cancelled,
}

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
  final BookingListStatus status;
  final String? clientPhone;
  final String? clientUsername;
  final String serviceEmoji;
  final int durationMinutes;
  final double price;
  final String? executorName;
  final String? notes;
  final int participantsCount;
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

  String get clientUsernameLabel {
    final raw = clientUsername?.trim();
    if (raw == null || raw.isEmpty) return '';
    return raw.startsWith('@') ? raw : '@$raw';
  }
}
