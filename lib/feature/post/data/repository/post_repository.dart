import 'package:clover/feature/post/data/models/post_feed_item.dart';
import 'package:clover/feature/post/data/models/post_model.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class PostRepository {
  /// Лента пользователя (enriched RPC или fallback select).
  Future<List<PostFeedItem>> listUserFeed({
    required String userId,
    int limit = 24,
    DateTime? cursorCreatedAt,
    String? cursorPostId,
    String? clusterId,
    bool onlyWithoutCluster = false,
  });

  /// Пост по id (с медиа).
  Future<PostModel?> getById(String postId);

  /// Enriched один пост.
  Future<PostFeedItem?> getPostEnriched(String postId);

  /// In-memory кэш (мгновенный UI).
  PostModel? getCachedPostById(String postId);

  void cachePost(PostModel post);
}

@LazySingleton(as: PostRepository)
class PostRepositoryImpl implements PostRepository {
  PostRepositoryImpl(this._client);

  final SupabaseClient _client;

  static const Duration _memoryTtl = Duration(minutes: 10);
  final Map<String, ({PostModel post, DateTime storedAt})> _memory = {};

  @override
  PostModel? getCachedPostById(String postId) {
    final id = postId.trim();
    if (id.isEmpty) return null;
    final e = _memory[id];
    if (e == null) return null;
    if (DateTime.now().difference(e.storedAt) > _memoryTtl) {
      _memory.remove(id);
      return null;
    }
    return e.post;
  }

  @override
  void cachePost(PostModel post) {
    final id = post.id.trim();
    if (id.isEmpty) return;
    _memory[id] = (post: post, storedAt: DateTime.now());
    if (_memory.length > 80) {
      for (final k in _memory.keys.take(20)) {
        _memory.remove(k);
      }
    }
  }

  @override
  Future<List<PostFeedItem>> listUserFeed({
    required String userId,
    int limit = 24,
    DateTime? cursorCreatedAt,
    String? cursorPostId,
    String? clusterId,
    bool onlyWithoutCluster = false,
  }) async {
    final uid = userId.trim();
    if (uid.isEmpty) return const [];

    try {
      final items = await _listEnrichedCursor(
        userId: uid,
        limit: limit,
        cursorCreatedAt: cursorCreatedAt,
        cursorPostId: cursorPostId,
        clusterId: clusterId,
        onlyWithoutCluster: onlyWithoutCluster,
      );

      if (items.isNotEmpty) return items;
    } catch (_) {
      // fallback ниже
    }

    return _listFallback(
      userId: uid,
      limit: limit,
      cursorCreatedAt: cursorCreatedAt,
      clusterId: clusterId,
      onlyWithoutCluster: onlyWithoutCluster,
    );
  }

  Future<List<PostFeedItem>> _listEnrichedCursor({
    required String userId,
    required int limit,
    DateTime? cursorCreatedAt,
    String? cursorPostId,
    String? clusterId,
    bool onlyWithoutCluster = false,
  }) async {
    final cid = clusterId?.trim();
    final hasCursor = cursorPostId != null && cursorCreatedAt != null && cursorPostId.trim().isNotEmpty;
    final pArgs = <String, dynamic>{
      'p_user_id': userId,
      'p_limit': limit,
      'p_cursor_created_at': hasCursor ? cursorCreatedAt.toUtc().toIso8601String() : null,
      'p_cursor_id': hasCursor ? cursorPostId : null,
      'p_cluster_id': (!onlyWithoutCluster && cid != null && cid.isNotEmpty) ? cid : null,
      'p_only_without_cluster': onlyWithoutCluster,
      'p_exclude_with_marker': true,
      'p_only_with_marker': false,
    };

    final res = await _client.rpc(
      'list_user_feed_enriched_cursor',
      params: <String, dynamic>{'p_args': pArgs},
    );

    return _consumeEnrichedRpc(res);
  }

  Future<List<PostFeedItem>> _listFallback({
    required String userId,
    required int limit,
    DateTime? cursorCreatedAt,
    String? clusterId,
    bool onlyWithoutCluster = false,
  }) async {
    var q = _client
        .from('posts')
        .select('*, post_media(*)')
        .eq('user_id', userId)
        .eq('is_archived', false)
        .isFilter('deleted_at', null);

    if (onlyWithoutCluster) {
      q = q.isFilter('cluster_id', null);
    } else {
      final cid = clusterId?.trim();
      if (cid != null && cid.isNotEmpty) {
        q = q.eq('cluster_id', cid);
      }
    }

    if (cursorCreatedAt != null) {
      q = q.lt('created_at', cursorCreatedAt.toUtc().toIso8601String());
    }

    final data = await q.order('created_at', ascending: false).limit(limit);
    final list = data as List<dynamic>;
    final items = <PostFeedItem>[];
    for (final raw in list) {
      if (raw is! Map) continue;
      final post = PostModel.fromJson(Map<String, dynamic>.from(raw));
      if (post.hasMarker) continue;
      cachePost(post);
      items.add(PostFeedItem(post: post));
    }
    return items;
  }

  Future<List<PostFeedItem>> _consumeEnrichedRpc(dynamic res) async {
    if (res is! List) return const [];

    final items = <PostFeedItem>[];
    for (final row in res) {
      if (row is! Map) continue;
      final m = Map<String, dynamic>.from(row);
      final postRaw = m['post'];
      if (postRaw is! Map) continue;

      final post = PostModel.fromJson(Map<String, dynamic>.from(postRaw));
      if (post.hasMarker) continue;
      cachePost(post);

      String? authorUsername;
      String? authorAvatarUrl;
      final authorRaw = m['author'];
      if (authorRaw is Map) {
        final am = Map<String, dynamic>.from(authorRaw);
        final u = (am['username'] as String?)?.trim();
        final a = (am['avatar_url'] as String?)?.trim();
        authorUsername = (u != null && u.isNotEmpty) ? u : null;
        authorAvatarUrl = (a != null && a.isNotEmpty) ? a : null;
      }

      final mySavedRaw = m['my_saved'];
      final mySaved = mySavedRaw is bool
          ? mySavedRaw
          : (mySavedRaw is String && (mySavedRaw == 'true' || mySavedRaw == 't'));

      String? myReaction;
      final reactionRaw = m['my_reaction'];
      if (reactionRaw is String) {
        final kind = reactionRaw.trim();
        if (kind == 'like' || kind == 'dislike') myReaction = kind;
      }

      items.add(
        PostFeedItem(
          post: post,
          authorUsername: authorUsername,
          authorAvatarUrl: authorAvatarUrl,
          myReaction: myReaction,
          mySaved: mySaved,
        ),
      );
    }
    return items;
  }

  @override
  Future<PostModel?> getById(String postId) async {
    final cached = getCachedPostById(postId);
    if (cached != null) return cached;

    final id = postId.trim();
    if (id.isEmpty) return null;

    final data = await _client.from('posts').select('*, post_media(*)').eq('id', id).maybeSingle();
    if (data == null) return null;
    final post = PostModel.fromJson(Map<String, dynamic>.from(data));
    cachePost(post);
    return post;
  }

  @override
  Future<PostFeedItem?> getPostEnriched(String postId) async {
    final id = postId.trim();
    if (id.isEmpty) return null;

    try {
      final res = await _client.rpc('get_post_enriched', params: {'p_post_id': id});
      final list = await _consumeEnrichedRpc(res);
      if (list.isNotEmpty) return list.first;
    } catch (_) {
      // fallback
    }

    final post = await getById(id);
    if (post == null) return null;
    return PostFeedItem(post: post);
  }
}
