import 'package:clover/feature/_booking_/booking_list/data/models/booking_list_item.dart';
import 'package:clover/feature/_booking_/shared/data/booking_error.dart';
import 'package:clover/feature/_booking_/shared/data/booking_json.dart';
import 'package:clover/feature/_booking_/shared/data/models/booking_status.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class BookingHostListRepository {
  Future<List<BookingListItem>> listBookings({
    required DateTime from,
    required DateTime to,
    String? query,
    Map<String, dynamic>? cursor,
    int limit = 50,
  });

  Future<void> rescheduleBooking({
    required String bookingId,
    required String staffId,
    required DateTime startsAt,
    BookingStatus resetStatus = BookingStatus.confirmed,
  });

  Future<void> updateBookingStatus(String bookingId, BookingStatus status);

  /// Откат последней смены статуса host-ом. Возвращает новый статус.
  Future<BookingStatus> revertBookingStatus(String bookingId);
}

@LazySingleton(as: BookingHostListRepository)
class BookingHostListRepositoryImpl implements BookingHostListRepository {
  BookingHostListRepositoryImpl(this._client);

  final SupabaseClient _client;

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } catch (e) {
      throw BookingException.from(e);
    }
  }

  @override
  Future<List<BookingListItem>> listBookings({
    required DateTime from,
    required DateTime to,
    String? query,
    Map<String, dynamic>? cursor,
    int limit = 50,
  }) async {
    return _guard(() async {
      final res = await _client.rpc('list_host_bookings_enriched', params: {
        'p_from': from.toUtc().toIso8601String(),
        'p_to': to.toUtc().toIso8601String(),
        'p_query': query,
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
  Future<void> rescheduleBooking({
    required String bookingId,
    required String staffId,
    required DateTime startsAt,
    BookingStatus resetStatus = BookingStatus.confirmed,
  }) async {
    final id = bookingId.trim();
    if (id.isEmpty) {
      throw const BookingException(BookingErrorCode.unknown, 'Не указана запись');
    }

    return _guard(() async {
      await _client.rpc('reschedule_booking', params: {
        'p_booking_id': id,
        'p_staff_id': staffId,
        'p_starts_at': startsAt.toUtc().toIso8601String(),
        'p_reset_status': resetStatus.dbValue,
      });
    });
  }

  @override
  Future<BookingStatus> revertBookingStatus(String bookingId) async {
    final id = bookingId.trim();
    if (id.isEmpty) {
      throw const BookingException(BookingErrorCode.unknown, 'Не указана запись');
    }

    return _guard(() async {
      final res = await _client.rpc('revert_booking_status', params: {
        'p_booking_id': id,
      });
      return BookingStatus.fromDbOrPending(res?.toString());
    });
  }

  @override
  Future<void> updateBookingStatus(String bookingId, BookingStatus status) async {
    final id = bookingId.trim();
    if (id.isEmpty) {
      throw const BookingException(BookingErrorCode.unknown, 'Не указана запись');
    }

    return _guard(() async {
      await _client.rpc('update_booking_status', params: {
        'p_booking_id': id,
        'p_status': status.dbValue,
      });
    });
  }

  BookingListItem _mapItem(Map<String, dynamic> row) {
    return BookingListItem(
      id: row['id']?.toString() ?? '',
      clientId: BookingJson.asString(row['client_id']),
      clientName: row['client_name']?.toString() ?? '',
      serviceTitle: row['service_title']?.toString() ?? '',
      startsAt: BookingJson.asIsoString(row['starts_at']) ?? '',
      status: BookingStatus.fromDbOrPending(row['status']?.toString()),
      clientPhone: BookingJson.asString(row['client_phone']),
      clientUsername: BookingJson.asString(row['client_username']),
      serviceEmoji: row['service_emoji']?.toString() ?? '💈',
      durationMinutes: BookingJson.asInt(row['duration_minutes'], fallback: 30),
      price: BookingJson.asDouble(row['price']),
      executorName: BookingJson.asString(row['executor_name']),
      notes: BookingJson.asString(row['notes']),
      participantsCount: BookingJson.asInt(row['participants_count'], fallback: 1),
      createdAt: BookingJson.asIsoString(row['created_at']),
    );
  }
}
