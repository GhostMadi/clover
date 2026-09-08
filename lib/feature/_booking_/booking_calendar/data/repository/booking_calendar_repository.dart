import 'package:clover/feature/_booking_/booking_calendar/data/models/booking_calendar_host.dart';
import 'package:clover/feature/_booking_/booking_calendar/data/models/booking_calendar_item.dart';
import 'package:clover/feature/_booking_/shared/data/booking_error.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

@lazySingleton
class BookingCalendarRepository {
  BookingCalendarRepository(this._client);

  final SupabaseClient _client;

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } catch (e) {
      throw BookingException.from(e);
    }
  }

  Future<List<BookingCalendarHost>> listHosts() async {
    return _guard(() async {
      final res = await _client.rpc('list_my_staff_booking_hosts');
      if (res is! List) return const [];
      return [
        for (final raw in res)
          if (raw is Map) BookingCalendarHost.fromJson(Map<String, dynamic>.from(raw)),
      ];
    });
  }

  Future<List<BookingCalendarItem>> listBookings({
    required DateTime from,
    required DateTime to,
    String? hostId,
    Map<String, dynamic>? cursor,
    int limit = 50,
  }) async {
    return _guard(() async {
      final params = <String, dynamic>{
        'p_from': from.toUtc().toIso8601String(),
        'p_to': to.toUtc().toIso8601String(),
        'p_cursor': cursor,
        'p_limit': limit,
      };
      final hid = hostId?.trim();
      if (hid != null && hid.isNotEmpty) {
        params['p_host_id'] = hid;
      }

      final res = await _client.rpc('list_my_staff_bookings_enriched', params: params);
      if (res is! List) return const [];
      return [
        for (final raw in res)
          if (raw is Map) BookingCalendarItem.fromJson(Map<String, dynamic>.from(raw)),
      ];
    });
  }
}
