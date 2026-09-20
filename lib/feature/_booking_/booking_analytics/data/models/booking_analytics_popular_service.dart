class BookingAnalyticsPopularService {
  const BookingAnalyticsPopularService({
    required this.serviceId,
    required this.title,
    required this.emojiText,
    required this.bookingCount,
  });

  final String serviceId;
  final String title;
  final String emojiText;
  final int bookingCount;

  Map<String, dynamic> toJson() => {
        'service_id': serviceId,
        'title': title,
        'emoji_text': emojiText,
        'booking_count': bookingCount,
      };

  factory BookingAnalyticsPopularService.fromJson(Map<String, dynamic> json) {
    return BookingAnalyticsPopularService(
      serviceId: json['service_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      emojiText: json['emoji_text']?.toString() ?? '💈',
      bookingCount: (json['booking_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class BookingAnalyticsPeriodResult {
  const BookingAnalyticsPeriodResult({
    required this.totalBookings,
    required this.popularServices,
  });

  final int totalBookings;
  final List<BookingAnalyticsPopularService> popularServices;
}
