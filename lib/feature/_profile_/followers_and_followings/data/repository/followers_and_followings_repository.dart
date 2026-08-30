import 'package:clover/feature/followers_and_followings/data/models/follow_profile_row.dart';
import 'package:clover/feature/social_graph/data/repository/social_graph_repository.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class FollowersAndFollowingsRepository {
  Future<List<FollowProfileRow>> listFollowers(String profileId, {int limit = 50, int offset = 0});

  Future<List<FollowProfileRow>> listFollowing(String profileId, {int limit = 50, int offset = 0});
}

@LazySingleton(as: FollowersAndFollowingsRepository)
class FollowersAndFollowingsRepositoryImpl implements FollowersAndFollowingsRepository {
  FollowersAndFollowingsRepositoryImpl(this._client, this._socialGraph);

  final SupabaseClient _client;
  final SocialGraphRepository _socialGraph;

  @override
  Future<List<FollowProfileRow>> listFollowers(String profileId, {int limit = 50, int offset = 0}) {
    return _list(
      rpcName: 'list_profile_followers',
      profileId: profileId,
      limit: limit,
      offset: offset,
    );
  }

  @override
  Future<List<FollowProfileRow>> listFollowing(String profileId, {int limit = 50, int offset = 0}) {
    return _list(
      rpcName: 'list_profile_following',
      profileId: profileId,
      limit: limit,
      offset: offset,
    );
  }

  Future<List<FollowProfileRow>> _list({
    required String rpcName,
    required String profileId,
    required int limit,
    required int offset,
  }) async {
    final id = profileId.trim();
    if (id.isEmpty) return const [];

    final res = await _client.rpc(
      rpcName,
      params: {
        'p_profile_id': id,
        'p_limit': limit,
        'p_offset': offset,
      },
    );

    final rows = _parseRows(res);
    return _enrichWithFollowState(rows);
  }

  List<FollowProfileRow> _parseRows(dynamic res) {
    if (res is! List) return const [];

    final rows = <FollowProfileRow>[];
    for (final raw in res) {
      if (raw is! Map) continue;
      final m = Map<String, dynamic>.from(raw);
      final profileId = m['profile_id']?.toString().trim();
      if (profileId == null || profileId.isEmpty) continue;

      rows.add(
        FollowProfileRow(
          profileId: profileId,
          username: m['username']?.toString(),
          avatarUrl: m['avatar_url']?.toString(),
        ),
      );
    }
    return rows;
  }

  Future<List<FollowProfileRow>> _enrichWithFollowState(List<FollowProfileRow> rows) async {
    final uid = _client.auth.currentUser?.id.trim();
    if (uid == null || uid.isEmpty) return rows;

    final enriched = await Future.wait(
      rows.map((row) async {
        if (row.profileId == uid) return row;
        try {
          final following = await _socialGraph.isFollowingUser(row.profileId);
          return row.copyWith(isFollowing: following);
        } catch (_) {
          return row;
        }
      }),
    );
    return enriched;
  }
}
