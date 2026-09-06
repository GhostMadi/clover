import 'package:clover/feature/_booking_/booking_create/data/models/booking_service_executor.dart';
import 'package:clover/feature/_booking_/booking_create/data/models/booking_staff_profile.dart';
import 'package:clover/feature/_booking_/shared/data/booking_error.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

@lazySingleton
class BookingStaffRepository {
  BookingStaffRepository(this._client);

  final SupabaseClient _client;

  String? get _uid => _client.auth.currentUser?.id.trim();

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } catch (e) {
      throw BookingException.from(e);
    }
  }

  Future<List<BookingServiceExecutor>> listMyStaff({bool activeOnly = true}) async {
    final uid = _uid;
    if (uid == null || uid.isEmpty) return const [];

    return _guard(() async {
      var query = _client.from('booking_staff').select('*, profiles:profile_id(avatar_url)').eq('host_id', uid);
      if (activeOnly) {
        query = query.eq('is_active', true);
      }
      final res = await query.order('sort_order').order('display_name');
      return [for (final row in res) _mapStaff(Map<String, dynamic>.from(row))];
    });
  }

  Future<List<BookingStaffProfile>> searchProfiles(
    String query, {
    Set<String> excludeProfileIds = const {},
  }) async {
    final uid = _uid;
    if (uid == null || uid.isEmpty) return const [];

    return _guard(() async {
      final q = query.trim();
      var builder = _client.from('profiles').select('id, username, full_name, avatar_url');

      builder = builder.neq('id', uid);

      if (q.isNotEmpty) {
        final pattern = '%$q%';
        builder = builder.or('username.ilike.$pattern,full_name.ilike.$pattern');
      }

      final res = await builder.order('username').limit(20);

      return [
        for (final raw in res)
          BookingStaffProfile(
            id: raw['id']?.toString().trim() ?? '',
            username: raw['username']?.toString() ?? 'noName',
            displayName: raw['full_name']?.toString(),
            avatarUrl: raw['avatar_url']?.toString(),
          ),
      ].where((profile) {
        if (profile.id.isEmpty) return false;
        if (excludeProfileIds.contains(profile.id)) return false;
        return true;
      }).toList();
    });
  }

  Future<BookingServiceExecutor> ensureStaffFromProfile(String profileId) async {
    final uid = _uid;
    if (uid == null || uid.isEmpty) {
      throw const BookingException(BookingErrorCode.notAuthenticated);
    }

    final id = profileId.trim();
    if (id.isEmpty) {
      throw const BookingException(BookingErrorCode.unknown, 'Не выбран аккаунт');
    }

    return _guard(() async {
      final existing = await _client
          .from('booking_staff')
          .select()
          .eq('host_id', uid)
          .eq('profile_id', id)
          .maybeSingle();

      if (existing != null) {
        return _mapStaff(Map<String, dynamic>.from(existing));
      }

      final profile = await _client
          .from('profiles')
          .select('id, username, full_name, avatar_url')
          .eq('id', id)
          .maybeSingle();

      if (profile == null) {
        throw const BookingException(BookingErrorCode.unknown, 'Аккаунт не найден');
      }

      final map = Map<String, dynamic>.from(profile);
      final username = map['username']?.toString().trim() ?? '';
      final fullName = map['full_name']?.toString().trim() ?? '';
      final displayName = fullName.isNotEmpty ? fullName : (username.isNotEmpty ? username : 'Пользователь');

      final res = await _client
          .from('booking_staff')
          .insert({
            'host_id': uid,
            'profile_id': id,
            'display_name': displayName,
            if (username.isNotEmpty) 'username': username,
          })
          .select()
          .single();

      return _mapStaff(
        Map<String, dynamic>.from(res),
        avatarUrl: map['avatar_url']?.toString(),
      );
    });
  }

  Future<BookingServiceExecutor> createStaff({
    required String displayName,
    String? username,
  }) async {
    final uid = _uid;
    if (uid == null || uid.isEmpty) {
      throw const BookingException(BookingErrorCode.notAuthenticated);
    }

    return _guard(() async {
      final res = await _client
          .from('booking_staff')
          .insert({
            'host_id': uid,
            'display_name': displayName.trim(),
            if (username != null && username.trim().isNotEmpty) 'username': username.trim(),
          })
          .select()
          .single();
      return _mapStaff(Map<String, dynamic>.from(res));
    });
  }

  Future<BookingServiceExecutor> updateStaff({
    required String id,
    required String displayName,
    String? username,
    bool? isActive,
  }) async {
    final uid = _uid;
    if (uid == null || uid.isEmpty) {
      throw const BookingException(BookingErrorCode.notAuthenticated);
    }

    return _guard(() async {
      final res = await _client
          .from('booking_staff')
          .update({
            'display_name': displayName.trim(),
            'username': username?.trim(),
            if (isActive != null) 'is_active': isActive,
          })
          .eq('id', id)
          .eq('host_id', uid)
          .select()
          .single();
      return _mapStaff(Map<String, dynamic>.from(res));
    });
  }

  BookingServiceExecutor _mapStaff(Map<String, dynamic> row, {String? avatarUrl}) {
    final profile = row['profiles'];
    final profileAvatar = profile is Map ? profile['avatar_url']?.toString() : null;
    return BookingServiceExecutor(
      id: row['id']?.toString() ?? '',
      displayName: row['display_name']?.toString() ?? '',
      username: row['username']?.toString() ?? '',
      profileId: row['profile_id']?.toString(),
      avatarUrl: avatarUrl ?? profileAvatar,
    );
  }
}
