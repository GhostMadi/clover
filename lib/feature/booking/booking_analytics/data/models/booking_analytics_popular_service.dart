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
}

class BookingAnalyticsPeriodResult {
  const BookingAnalyticsPeriodResult({
    required this.totalBookings,
    required this.popularServices,
  });

  final int totalBookings;
  final List<BookingAnalyticsPopularService> popularServices;
}
