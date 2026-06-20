import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class SocialGraphRepository {
  Future<void> followUser(String targetUserId);

  Future<void> unfollowUser(String targetUserId);

  Future<bool> isFollowingUser(String targetUserId);
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
}
