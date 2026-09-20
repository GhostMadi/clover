import 'package:clover/feature/_booking_/booking_analytics/data/models/booking_analytics_popular_service.dart';
import 'package:clover/feature/_booking_/shared/data/booking_error.dart';
import 'package:clover/feature/_booking_/shared/data/booking_json.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BookingAnalyticsResult {
  const BookingAnalyticsResult({
    required this.totalBookings,
    required this.pendingBookings,
    required this.confirmedBookings,
    required this.completedBookings,
    required this.cancelledBookings,
    required this.revenue,
    required this.avgCheck,
    required this.popularServices,
    required this.topStaff,
  });

  final int totalBookings;
  final int pendingBookings;
  final int confirmedBookings;
  final int completedBookings;
  final int cancelledBookings;
  final double revenue;
  final double avgCheck;
  final List<BookingAnalyticsPopularService> popularServices;
  final List<BookingAnalyticsStaffStat> topStaff;

  Map<String, dynamic> toJson() => {
        'total_bookings': totalBookings,
        'pending_bookings': pendingBookings,
        'confirmed_bookings': confirmedBookings,
        'completed_bookings': completedBookings,
        'cancelled_bookings': cancelledBookings,
        'revenue': revenue,
        'avg_check': avgCheck,
        'popular_services': [
          for (final s in popularServices) s.toJson(),
        ],
        'top_staff': [
          for (final s in topStaff) s.toJson(),
        ],
      };

  factory BookingAnalyticsResult.fromJson(Map<String, dynamic> json) {
    final popularRaw = json['popular_services'];
    final topStaffRaw = json['top_staff'];
    return BookingAnalyticsResult(
      totalBookings: BookingJson.asInt(json['total_bookings']),
      pendingBookings: BookingJson.asInt(json['pending_bookings']),
      confirmedBookings: BookingJson.asInt(json['confirmed_bookings']),
      completedBookings: BookingJson.asInt(json['completed_bookings']),
      cancelledBookings: BookingJson.asInt(json['cancelled_bookings']),
      revenue: BookingJson.asDouble(json['revenue']),
      avgCheck: BookingJson.asDouble(json['avg_check']),
      popularServices: popularRaw is List
          ? [
              for (final item in popularRaw)
                if (item is Map)
                  BookingAnalyticsPopularService.fromJson(Map<String, dynamic>.from(item)),
            ]
          : const [],
      topStaff: topStaffRaw is List
          ? [
              for (final item in topStaffRaw)
                if (item is Map)
                  BookingAnalyticsStaffStat.fromJson(Map<String, dynamic>.from(item)),
            ]
          : const [],
    );
  }
}

class BookingAnalyticsStaffStat {
  const BookingAnalyticsStaffStat({
    required this.staffId,
    required this.displayName,
    required this.bookingCount,
    required this.revenue,
    required this.completedCount,
  });

  final String staffId;
  final String displayName;
  final int bookingCount;
  final double revenue;
  final int completedCount;

  Map<String, dynamic> toJson() => {
        'staff_id': staffId,
        'display_name': displayName,
        'booking_count': bookingCount,
        'revenue': revenue,
        'completed_count': completedCount,
      };

  factory BookingAnalyticsStaffStat.fromJson(Map<String, dynamic> json) => BookingAnalyticsStaffStat(
        staffId: json['staff_id']?.toString() ?? '',
        displayName: json['display_name']?.toString() ?? '',
        bookingCount: BookingJson.asInt(json['booking_count']),
        revenue: BookingJson.asDouble(json['revenue']),
        completedCount: BookingJson.asInt(json['completed_count']),
      );
}

@lazySingleton
class BookingAnalyticsRepository {
  BookingAnalyticsRepository(this._client);

  final SupabaseClient _client;

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } catch (e) {
      throw BookingException.from(e);
    }
  }

  Future<BookingAnalyticsResult> load({
    required DateTime start,
    required DateTime end,
    String? staffId,
    String? pointId,
  }) async {
    return _guard(() async {
      final res = await _client.rpc('get_booking_analytics', params: {
        'p_from': _dateKey(start),
        'p_to': _dateKey(end),
        'p_staff_id': staffId,
        if (pointId != null && pointId.trim().isNotEmpty) 'p_point_id': pointId.trim(),
      });

      if (res is! Map) {
        return const BookingAnalyticsResult(
          totalBookings: 0,
          pendingBookings: 0,
          confirmedBookings: 0,
          completedBookings: 0,
          cancelledBookings: 0,
          revenue: 0,
          avgCheck: 0,
          popularServices: [],
          topStaff: [],
        );
      }

      final map = Map<String, dynamic>.from(res);
      final popularRaw = map['popular_services'];
      final topStaffRaw = map['top_staff'];

      return BookingAnalyticsResult(
        totalBookings: BookingJson.asInt(map['total_bookings']),
        pendingBookings: BookingJson.asInt(map['pending_bookings']),
        confirmedBookings: BookingJson.asInt(map['confirmed_bookings']),
        completedBookings: BookingJson.asInt(map['completed_bookings']),
        cancelledBookings: BookingJson.asInt(map['cancelled_bookings']),
        revenue: BookingJson.asDouble(map['revenue']),
        avgCheck: BookingJson.asDouble(map['avg_check']),
        popularServices: popularRaw is List
            ? [
                for (final item in popularRaw)
                  if (item is Map)
                    BookingAnalyticsPopularService(
                      serviceId: item['service_id']?.toString() ?? '',
                      title: item['title']?.toString() ?? '',
                      emojiText: item['emoji_text']?.toString() ?? '💈',
                      bookingCount: BookingJson.asInt(item['booking_count']),
                    ),
              ]
            : const [],
        topStaff: topStaffRaw is List
            ? [
                for (final item in topStaffRaw)
                  if (item is Map)
                    BookingAnalyticsStaffStat(
                      staffId: item['staff_id']?.toString() ?? '',
                      displayName: item['display_name']?.toString() ?? '',
                      bookingCount: BookingJson.asInt(item['booking_count']),
                      revenue: BookingJson.asDouble(item['revenue']),
                      completedCount: BookingJson.asInt(item['completed_count']),
                    ),
              ]
            : const [],
      );
    });
  }

  String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
