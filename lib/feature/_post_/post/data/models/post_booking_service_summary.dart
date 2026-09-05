/// Краткие данные услуги из `get_post_enriched` → `post.booking_service`.
class PostBookingServiceSummary {
  const PostBookingServiceSummary({
    required this.id,
    required this.title,
    required this.emojiText,
    required this.price,
    required this.durationMinutes,
    required this.isActive,
  });

  final String id;
  final String title;
  final String emojiText;
  final double price;
  final int durationMinutes;
  final bool isActive;

  String get priceLabel {
    if (price == price.roundToDouble()) {
      return '${price.toInt()} ₸';
    }
    return '${price.toStringAsFixed(0)} ₸';
  }

  String get subtitle => '$emojiText $title · $durationMinutes мин · $priceLabel';

  static PostBookingServiceSummary? tryFromJson(dynamic raw) {
    if (raw == null) return null;
    if (raw is! Map) return null;

    final json = Map<String, dynamic>.from(raw);
    final id = json['id']?.toString().trim();
    if (id == null || id.isEmpty) return null;

    final priceRaw = json['price'];
    final price = switch (priceRaw) {
      num n => n.toDouble(),
      String s => double.tryParse(s) ?? 0,
      _ => 0.0,
    };

    return PostBookingServiceSummary(
      id: id,
      title: json['title']?.toString() ?? '',
      emojiText: json['emoji_text']?.toString() ?? '💈',
      price: price,
      durationMinutes: (json['duration_minutes'] as num?)?.toInt() ?? 30,
      isActive: json['is_active'] == true || json['is_active'] == null,
    );
  }
}
