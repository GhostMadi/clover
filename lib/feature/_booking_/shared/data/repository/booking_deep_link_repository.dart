import 'package:clover/feature/_booking_/booking_list/data/models/booking_list_item.dart';
import 'package:clover/feature/_booking_/my_bookings/data/models/my_booking_item.dart';
import 'package:clover/feature/_booking_/shared/data/booking_error.dart';
import 'package:clover/feature/_booking_/shared/data/booking_json.dart';
import 'package:clover/feature/_booking_/shared/data/models/booking_status.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

sealed class BookingDeepLinkTarget {
  const BookingDeepLinkTarget();
}

final class BookingDeepLinkClientTarget extends BookingDeepLinkTarget {
  const BookingDeepLinkClientTarget(this.item);

  final MyBookingItem item;
}

final class BookingDeepLinkHostTarget extends BookingDeepLinkTarget {
  const BookingDeepLinkHostTarget(this.item);

  final BookingListItem item;
}

abstract class BookingDeepLinkRepository {
  Future<BookingDeepLinkTarget?> resolveBooking(String bookingId);
}

@LazySingleton(as: BookingDeepLinkRepository)
class BookingDeepLinkRepositoryImpl implements BookingDeepLinkRepository {
  BookingDeepLinkRepositoryImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<BookingDeepLinkTarget?> resolveBooking(String bookingId) async {
    final id = bookingId.trim();
    if (id.isEmpty) return null;

    try {
      final res = await _client.rpc('get_booking_enriched_for_viewer', params: {'p_booking_id': id});
      if (res is! Map) return null;

      final map = Map<String, dynamic>.from(res);
      final role = map['role']?.toString();
      final itemRaw = map['item'];
      if (itemRaw is! Map) return null;
      final item = Map<String, dynamic>.from(itemRaw);

      return switch (role) {
        'client' => BookingDeepLinkClientTarget(_mapMyBooking(item)),
        'host' => BookingDeepLinkHostTarget(_mapHostBooking(item)),
        _ => null,
      };
    } catch (e) {
      throw BookingException.from(e);
    }
  }

  MyBookingItem _mapMyBooking(Map<String, dynamic> row) {
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

  BookingListItem _mapHostBooking(Map<String, dynamic> row) {
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
