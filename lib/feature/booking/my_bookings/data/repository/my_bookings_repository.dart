import 'package:clover/feature/booking/my_bookings/data/models/my_booking_item.dart';
import 'package:clover/feature/booking/shared/data/booking_error.dart';
import 'package:clover/feature/booking/shared/data/booking_json.dart';
import 'package:clover/feature/booking/shared/data/models/booking_status.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class MyBookingsRepository {
  Future<List<MyBookingItem>> listBookings({
    required DateTime from,
    required DateTime to,
    Map<String, dynamic>? cursor,
    int limit = 50,
  });

  Future<void> cancelBooking(String bookingId);
}

@LazySingleton(as: MyBookingsRepository)
class MyBookingsRepositoryImpl implements MyBookingsRepository {
  MyBookingsRepositoryImpl(this._client);

  final SupabaseClient _client;

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } catch (e) {
      throw BookingException.from(e);
    }
  }

  @override
  Future<List<MyBookingItem>> listBookings({
    required DateTime from,
    required DateTime to,
    Map<String, dynamic>? cursor,
    int limit = 50,
  }) async {
    return _guard(() async {
      final res = await _client.rpc('list_my_bookings_enriched', params: {
        'p_from': from.toUtc().toIso8601String(),
        'p_to': to.toUtc().toIso8601String(),
        'p_cursor': cursor,
        'p_limit': limit,
      });

      if (res is! List) return const [];
      return [
        for (final raw in res)
          if (raw is Map) _mapItem(Map<String, dynamic>.from(raw)),
      ];
    });
  }

  @override
  Future<void> cancelBooking(String bookingId) async {
    final id = bookingId.trim();
    if (id.isEmpty) {
      throw const BookingException(BookingErrorCode.unknown, 'Не указана запись');
    }

    return _guard(() async {
      await _client.rpc('update_booking_status', params: {
        'p_booking_id': id,
        'p_status': 'cancelled',
      });
    });
  }

  MyBookingItem _mapItem(Map<String, dynamic> row) {
    return MyBookingItem(
      id: row['id']?.toString() ?? '',
      hostId: row['host_id']?.toString() ?? '',
      hostDisplayName: row['host_display_name']?.toString() ?? '',
      hostUsername: BookingJson.asString(row['host_username']),
      serviceTitle: row['service_title']?.toString() ?? '',
      serviceEmoji: row['service_emoji']?.toString() ?? '💈',
      durationMinutes: BookingJson.asInt(row['duration_minutes'], fallback: 30),
      price: BookingJson.asDouble(row['price']),
      executorName: BookingJson.asString(row['executor_name']),
      startsAt: BookingJson.asIsoString(row['starts_at']) ?? '',
      status: BookingStatus.fromDbOrPending(row['status']?.toString()),
      notes: BookingJson.asString(row['notes']),
      createdAt: BookingJson.asIsoString(row['created_at']),
    );
  }
}
