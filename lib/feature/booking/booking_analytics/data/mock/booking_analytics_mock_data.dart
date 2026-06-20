import 'package:clover/feature/booking/booking_analytics/data/models/booking_analytics_popular_service.dart';
import 'package:clover/feature/booking/booking_analytics/data/models/booking_analytics_user.dart';

abstract final class BookingAnalyticsMockData {
  static const users = [
    BookingAnalyticsUser(id: 'exec-1', displayName: 'Алия К.', username: 'aliya_k'),
    BookingAnalyticsUser(id: 'exec-2', displayName: 'Марат Т.', username: 'marat_t'),
    BookingAnalyticsUser(id: 'exec-3', displayName: 'Diana S.', username: 'diana_s'),
  ];

  static const _weekAll = [
    BookingAnalyticsPopularService(serviceId: '1', title: 'Стрижка мужская', emojiText: '💈', bookingCount: 18),
    BookingAnalyticsPopularService(serviceId: '3', title: 'Маникюр', emojiText: '💅', bookingCount: 11),
    BookingAnalyticsPopularService(serviceId: '2', title: 'Консультация', emojiText: '💬', bookingCount: 6),
  ];

  static const _monthAll = [
    BookingAnalyticsPopularService(serviceId: '1', title: 'Стрижка мужская', emojiText: '💈', bookingCount: 64),
    BookingAnalyticsPopularService(serviceId: '3', title: 'Маникюр', emojiText: '💅', bookingCount: 41),
    BookingAnalyticsPopularService(serviceId: '2', title: 'Консультация', emojiText: '💬', bookingCount: 22),
  ];

  static const _customAll = [
    BookingAnalyticsPopularService(serviceId: '2', title: 'Консультация', emojiText: '💬', bookingCount: 9),
    BookingAnalyticsPopularService(serviceId: '1', title: 'Стрижка мужская', emojiText: '💈', bookingCount: 7),
  ];

  static const _aliyaWeek = [
    BookingAnalyticsPopularService(serviceId: '1', title: 'Стрижка мужская', emojiText: '💈', bookingCount: 12),
    BookingAnalyticsPopularService(serviceId: '2', title: 'Консультация', emojiText: '💬', bookingCount: 3),
  ];

  static const _maratWeek = [
    BookingAnalyticsPopularService(serviceId: '2', title: 'Консультация', emojiText: '💬', bookingCount: 8),
    BookingAnalyticsPopularService(serviceId: '1', title: 'Стрижка мужская', emojiText: '💈', bookingCount: 2),
  ];

  static const _dianaWeek = [
    BookingAnalyticsPopularService(serviceId: '3', title: 'Маникюр', emojiText: '💅', bookingCount: 9),
    BookingAnalyticsPopularService(serviceId: '1', title: 'Стрижка мужская', emojiText: '💈', bookingCount: 1),
  ];

  static const _aliyaMonth = [
    BookingAnalyticsPopularService(serviceId: '1', title: 'Стрижка мужская', emojiText: '💈', bookingCount: 38),
    BookingAnalyticsPopularService(serviceId: '2', title: 'Консультация', emojiText: '💬', bookingCount: 9),
  ];

  static const _maratMonth = [
    BookingAnalyticsPopularService(serviceId: '2', title: 'Консультация', emojiText: '💬', bookingCount: 14),
    BookingAnalyticsPopularService(serviceId: '1', title: 'Стрижка мужская', emojiText: '💈', bookingCount: 6),
  ];

  static const _dianaMonth = [
    BookingAnalyticsPopularService(serviceId: '3', title: 'Маникюр', emojiText: '💅', bookingCount: 28),
    BookingAnalyticsPopularService(serviceId: '1', title: 'Стрижка мужская', emojiText: '💈', bookingCount: 5),
  ];

  static BookingAnalyticsUser? userById(String? id) {
    if (id == null || id.isEmpty) return null;
    for (final user in users) {
      if (user.id == id) return user;
    }
    return null;
  }

  static BookingAnalyticsPeriodResult forPeriod({
    required DateTime start,
    required DateTime end,
    String? userId,
  }) {
    final normalizedStart = DateTime(start.year, start.month, start.day);
    final normalizedEnd = DateTime(end.year, end.month, end.day);
    final days = normalizedEnd.difference(normalizedStart).inDays + 1;

    if (userId != null) {
      return _forUser(userId, days: days);
    }

    if (days <= 8) {
      return const BookingAnalyticsPeriodResult(totalBookings: 35, popularServices: _weekAll);
    }
    if (days <= 31) {
      return const BookingAnalyticsPeriodResult(totalBookings: 127, popularServices: _monthAll);
    }
    return const BookingAnalyticsPeriodResult(totalBookings: 18, popularServices: _customAll);
  }

  static BookingAnalyticsPeriodResult _forUser(String userId, {required int days}) {
    final isMonth = days > 8;

    final (total, services) = switch (userId) {
      'exec-1' => isMonth ? (47, _aliyaMonth) : (15, _aliyaWeek),
      'exec-2' => isMonth ? (20, _maratMonth) : (10, _maratWeek),
      'exec-3' => isMonth ? (33, _dianaMonth) : (10, _dianaWeek),
      _ => (0, const <BookingAnalyticsPopularService>[]),
    };

    return BookingAnalyticsPeriodResult(totalBookings: total, popularServices: services);
  }

  static String formatPeriodLabel(DateTime start, DateTime end) {
    const months = [
      'янв',
      'фев',
      'мар',
      'апр',
      'май',
      'июн',
      'июл',
      'авг',
      'сен',
      'окт',
      'ноя',
      'дек',
    ];

    final sameMonth = start.year == end.year && start.month == end.month;
    if (sameMonth && start.day == 1 && end.day >= 28) {
      return '${months[start.month - 1]} ${start.year}';
    }

    final startLabel = '${start.day} ${months[start.month - 1]}';
    final endLabel = '${end.day} ${months[end.month - 1]}';
    if (start.year == end.year) {
      return '$startLabel — $endLabel ${start.year}';
    }
    return '$startLabel ${start.year} — $endLabel ${end.year}';
  }
}
