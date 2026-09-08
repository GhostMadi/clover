import 'package:clover/feature/_booking_/booking_create/data/models/booking_service_executor.dart';
import 'package:clover/feature/_booking_/booking_create/data/models/booking_staff_invite.dart';
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

  Future<List<BookingStaffInvite>> listPendingInvites() async {
    final uid = _uid;
    if (uid == null || uid.isEmpty) return const [];

    return _guard(() async {
      final res = await _client.rpc('list_booking_staff_invites_pending');
      if (res is! List) return const [];
      return [
        for (final raw in res)
          if (raw is Map) BookingStaffInvite.fromJson(Map<String, dynamic>.from(raw)),
      ].where((invite) => invite.id.isNotEmpty).toList();
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

  /// Invite Clover account via DM. Linked staff is created only after Accept.
  Future<String> inviteStaff(String profileId) async {
    final uid = _uid;
    if (uid == null || uid.isEmpty) {
      throw const BookingException(BookingErrorCode.notAuthenticated);
    }

    final id = profileId.trim();
    if (id.isEmpty) {
      throw const BookingException(BookingErrorCode.unknown, 'Не выбран аккаунт');
    }

    return _guard(() async {
      final res = await _client.rpc('booking_invite_staff', params: {'p_profile_id': id});
      final inviteId = res?.toString().trim() ?? '';
      if (inviteId.isEmpty) {
        throw const BookingException(BookingErrorCode.unknown, 'Не удалось отправить приглашение');
      }
      return inviteId;
    });
  }

  Future<void> acceptInvite(String inviteId) async {
    final id = inviteId.trim();
    if (id.isEmpty) {
      throw const BookingException(BookingErrorCode.unknown, 'Нет заявки');
    }
    await _guard(() async {
      await _client.rpc('booking_accept_staff_invite', params: {'p_invite_id': id});
    });
  }

  Future<void> rejectInvite(String inviteId) async {
    final id = inviteId.trim();
    if (id.isEmpty) {
      throw const BookingException(BookingErrorCode.unknown, 'Нет заявки');
    }
    await _guard(() async {
      await _client.rpc('booking_reject_staff_invite', params: {'p_invite_id': id});
    });
  }

  Future<void> cancelInvite(String inviteId) async {
    final id = inviteId.trim();
    if (id.isEmpty) {
      throw const BookingException(BookingErrorCode.unknown, 'Нет заявки');
    }
    await _guard(() async {
      await _client.rpc('booking_cancel_staff_invite', params: {'p_invite_id': id});
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
