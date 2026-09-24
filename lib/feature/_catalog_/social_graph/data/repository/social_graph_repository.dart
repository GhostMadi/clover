import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BlockedProfileRow {
  const BlockedProfileRow({
    required this.profileId,
    this.username,
    this.avatarUrl,
  });

  final String profileId;
  final String? username;
  final String? avatarUrl;
}

abstract class SocialGraphRepository {
  Future<void> followUser(String targetUserId);

  Future<void> unfollowUser(String targetUserId);

  Future<bool> isFollowingUser(String targetUserId);

  /// Batch follow flags for [targetUserIds]. Missing ids → false.
  Future<Map<String, bool>> isFollowingUsers(List<String> targetUserIds);

  Future<void> blockUser(
    String targetUserId, {
    String reason = 'abusive_user',
    String? postId,
    String? note,
  });

  Future<void> unblockUser(String targetUserId);

  Future<List<BlockedProfileRow>> listMyBlockedUsers({int limit = 50, int offset = 0});
}

@LazySingleton(as: SocialGraphRepository)
class SocialGraphRepositoryImpl implements SocialGraphRepository {
  SocialGraphRepositoryImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<void> followUser(String targetUserId) async {
    final id = targetUserId.trim();
    if (id.isEmpty) throw ArgumentError('targetUserId');
    await _client.rpc('follow_user', params: {'p_target': id});
  }

  @override
  Future<void> unfollowUser(String targetUserId) async {
    final id = targetUserId.trim();
    if (id.isEmpty) throw ArgumentError('targetUserId');
    await _client.rpc('unfollow_user', params: {'p_target': id});
  }

  @override
  Future<bool> isFollowingUser(String targetUserId) async {
    final id = targetUserId.trim();
    if (id.isEmpty) return false;
    final res = await _client.rpc('is_following_user', params: {'p_target': id});
    return res == true;
  }

  @override
  Future<Map<String, bool>> isFollowingUsers(List<String> targetUserIds) async {
    final ids = <String>{
      for (final raw in targetUserIds)
        if (raw.trim().isNotEmpty) raw.trim(),
    };
    if (ids.isEmpty) return const {};

    final res = await _client.rpc(
      'is_following_users',
      params: {'p_targets': ids.toList()},
    );

    final out = <String, bool>{for (final id in ids) id: false};
    if (res is! List) return out;

    for (final raw in res) {
      if (raw is! Map) continue;
      final m = Map<String, dynamic>.from(raw);
      final id = m['profile_id']?.toString().trim();
      if (id == null || id.isEmpty) continue;
      out[id] = m['is_following'] == true;
    }
    return out;
  }

  @override
  Future<void> blockUser(
    String targetUserId, {
    String reason = 'abusive_user',
    String? postId,
    String? note,
  }) async {
    final id = targetUserId.trim();
    if (id.isEmpty) throw ArgumentError('targetUserId');
    await _client.rpc(
      'block_user',
      params: {
        'p_target': id,
        'p_reason': reason.trim().isEmpty ? 'abusive_user' : reason.trim(),
        if (postId != null && postId.trim().isNotEmpty) 'p_post_id': postId.trim(),
        if (note != null && note.trim().isNotEmpty) 'p_note': note.trim(),
      },
    );
  }

  @override
  Future<void> unblockUser(String targetUserId) async {
    final id = targetUserId.trim();
    if (id.isEmpty) throw ArgumentError('targetUserId');
    await _client.rpc('unblock_user', params: {'p_target': id});
  }

  @override
  Future<List<BlockedProfileRow>> listMyBlockedUsers({
    int limit = 50,
    int offset = 0,
  }) async {
    final res = await _client.rpc(
      'list_my_blocked_users',
      params: {
        'p_limit': limit,
        'p_offset': offset,
      },
    );
    if (res is! List) return const [];

    final rows = <BlockedProfileRow>[];
    for (final raw in res) {
      if (raw is! Map) continue;
      final m = Map<String, dynamic>.from(raw);
      final profileId = m['profile_id']?.toString().trim();
      if (profileId == null || profileId.isEmpty) continue;
      rows.add(
        BlockedProfileRow(
          profileId: profileId,
          username: m['username']?.toString(),
          avatarUrl: m['avatar_url']?.toString(),
        ),
      );
    }
    return rows;
  }
}
