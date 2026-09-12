import 'package:clover/feature/_booking_/booking_points/data/models/booking_point.dart';
import 'package:clover/feature/_booking_/shared/data/booking_error.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

@lazySingleton
class BookingPointsRepository {
  BookingPointsRepository(this._client);

  final SupabaseClient _client;

  String? get _uid => _client.auth.currentUser?.id.trim();

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } catch (e) {
      throw BookingException.from(e);
    }
  }

  Future<String> ensureDefaultPointId() async {
    return _guard(() async {
      final raw = await _client.rpc('booking_ensure_default_point');
      final id = raw?.toString().trim() ?? '';
      if (id.isEmpty) {
        throw const BookingException(BookingErrorCode.unknown);
      }
      return id;
    });
  }

  Future<List<BookingPoint>> listMyPoints() async {
    final uid = _uid;
    if (uid == null || uid.isEmpty) return const [];

    return _guard(() async {
      final res = await _client
          .from('booking_points')
          .select('id, host_id, name, created_at')
          .eq('host_id', uid)
          .isFilter('archived_at', null)
          .order('created_at');

      final points = [
        for (final row in res) BookingPoint.fromJson(Map<String, dynamic>.from(row)),
      ];

      if (points.isNotEmpty) return points;

      final id = await ensureDefaultPointId();
      final again = await _client
          .from('booking_points')
          .select('id, host_id, name, created_at')
          .eq('id', id)
          .maybeSingle();
      if (again == null) return const [];
      return [BookingPoint.fromJson(Map<String, dynamic>.from(again))];
    });
  }

  Future<BookingPoint?> getPoint(String pointId) async {
    final id = pointId.trim();
    if (id.isEmpty) return null;

    return _guard(() async {
      final row = await _client
          .from('booking_points')
          .select('id, host_id, name, created_at')
          .eq('id', id)
          .isFilter('archived_at', null)
          .maybeSingle();
      if (row == null) return null;
      return BookingPoint.fromJson(Map<String, dynamic>.from(row));
    });
  }

  Future<BookingPoint> createPoint(String name) async {
    final uid = _uid;
    if (uid == null || uid.isEmpty) {
      throw const BookingException(BookingErrorCode.notAuthenticated);
    }
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw const BookingException(BookingErrorCode.unknown);
    }

    return _guard(() async {
      final row = await _client
          .from('booking_points')
          .insert({'host_id': uid, 'name': trimmed})
          .select('id, host_id, name, created_at')
          .single();
      return BookingPoint.fromJson(Map<String, dynamic>.from(row));
    });
  }

  Future<void> renamePoint({required String pointId, required String name}) async {
    final id = pointId.trim();
    final trimmed = name.trim();
    if (id.isEmpty || trimmed.isEmpty) {
      throw const BookingException(BookingErrorCode.unknown);
    }

    return _guard(() async {
      await _client.from('booking_points').update({'name': trimmed}).eq('id', id);
    });
  }
}
