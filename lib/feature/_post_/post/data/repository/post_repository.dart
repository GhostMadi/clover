import 'package:cached_network_image/cached_network_image.dart';
import 'package:clover/feature/_post_/post/data/models/post_feed_item.dart';
import 'package:clover/feature/_post_/post/data/models/post_model.dart';
import 'package:clover/feature/_post_/post/data/repository/post_feed_enriched_parser.dart';
import 'package:clover/feature/_post_/post/data/repository/post_local_cache.dart';
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
    bool onlyWithMarker = false,
    bool excludeWithMarker = true,
    Set<String> filterSelectionKeys = const {},
  });

  /// Пост по id (с медиа).
  Future<PostModel?> getById(String postId);

  /// Enriched один пост.
  Future<PostFeedItem?> getPostEnriched(String postId);

  /// In-memory кэш (мгновенный UI).
  PostModel? getCachedPostById(String postId);

  /// Enriched item из ленты / get_post_enriched (маркер, автор, реакция).
  PostFeedItem? getCachedFeedItem(String postId);

  void cacheFeedItem(PostFeedItem item);

  void cachePost(PostModel post);

  /// In-memory кэш моей реакции на пост (`like` | `dislike` | null).
  bool hasCachedMyReaction(String postId);

  String? getCachedMyReaction(String postId);

  void cacheMyReaction(String postId, String? reaction);

  /// In-memory кэш «сохранено мной».
  bool hasCachedMySaved(String postId);

  bool getCachedMySaved(String postId);

  void cacheMySaved(String postId, bool saved);

  /// Сброс in-memory кэша (logout / смена аккаунта).
  void clearMemoryCache();

  /// `like` | `dislike` | null — снять реакцию.
  Future<String?> setPostReaction(String postId, String? kind);

  /// Сохранить или убрать пост из сохранённых.
  Future<void> setPostSaved(String postId, bool saved);

  /// Привязка поста к кластеру; [clusterId] = null — отвязать.
  Future<void> setPostCluster(String postId, {String? clusterId});

  /// Архивировать публикацию или ивент ([markerId] — архив маркера, иначе posts.is_archived).
  Future<void> archivePost(String postId, {String? markerId});

  /// Разархивировать публикацию или ивент.
  Future<void> unarchivePost(String postId, {String? markerId});

  /// Безвозвратно удалить публикацию, все файлы в Storage и связанные кэши.
  Future<void> deletePost(String postId, {PostModel? cachedPost});
}

@LazySingleton(as: PostRepository)
class PostRepositoryImpl implements PostRepository {
  PostRepositoryImpl(this._client, this._localCache);

  final SupabaseClient _client;
  final PostLocalCache _localCache;

  static const Duration _memoryTtl = Duration(minutes: 10);
  final Map<String, ({PostModel post, DateTime storedAt})> _memory = {};
  final Map<String, ({PostFeedItem item, DateTime storedAt})> _feedMemory = {};
  final Map<String, ({String? reaction, DateTime storedAt})> _reactionMemory = {};
  final Map<String, ({bool saved, DateTime storedAt})> _savedMemory = {};

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
  bool hasCachedMyReaction(String postId) {
    final id = postId.trim();
    if (id.isEmpty) return false;
    final e = _reactionMemory[id];
    if (e == null) return false;
    if (DateTime.now().difference(e.storedAt) > _memoryTtl) {
      _reactionMemory.remove(id);
      return false;
    }
    return true;
  }

  @override
  String? getCachedMyReaction(String postId) {
    if (!hasCachedMyReaction(postId)) return null;
    return _reactionMemory[postId.trim()]!.reaction;
  }

  @override
  void cacheMyReaction(String postId, String? reaction) {
    final id = postId.trim();
    if (id.isEmpty) return;
    final normalized = reaction?.trim();
    final value = (normalized == 'like' || normalized == 'dislike') ? normalized : null;
    _reactionMemory[id] = (reaction: value, storedAt: DateTime.now());
    if (_reactionMemory.length > 200) {
      for (final k in _reactionMemory.keys.take(40)) {
        _reactionMemory.remove(k);
      }
    }
  }

  @override
  bool hasCachedMySaved(String postId) {
    final id = postId.trim();
    if (id.isEmpty) return false;
    final e = _savedMemory[id];
    if (e == null) return false;
    if (DateTime.now().difference(e.storedAt) > _memoryTtl) {
      _savedMemory.remove(id);
      return false;
    }
    return true;
  }

  @override
  bool getCachedMySaved(String postId) {
    if (!hasCachedMySaved(postId)) return false;
    return _savedMemory[postId.trim()]!.saved;
  }

  @override
  void cacheMySaved(String postId, bool saved) {
    final id = postId.trim();
    if (id.isEmpty) return;
    _savedMemory[id] = (saved: saved, storedAt: DateTime.now());
    if (_savedMemory.length > 200) {
      for (final k in _savedMemory.keys.take(40)) {
        _savedMemory.remove(k);
      }
    }
  }

  @override
  PostFeedItem? getCachedFeedItem(String postId) {
    final id = postId.trim();
    if (id.isEmpty) return null;
    final e = _feedMemory[id];
    if (e == null) return null;
    if (DateTime.now().difference(e.storedAt) > _memoryTtl) {
      _feedMemory.remove(id);
      return null;
    }
    return e.item;
  }

  @override
  void cacheFeedItem(PostFeedItem item) {
    final id = item.post.id.trim();
    if (id.isEmpty) return;
    _feedMemory[id] = (item: item, storedAt: DateTime.now());
    cachePost(item.post);
    cacheMyReaction(id, item.myReaction);
    cacheMySaved(id, item.mySaved);
    if (_feedMemory.length > 80) {
      for (final k in _feedMemory.keys.take(20)) {
        _feedMemory.remove(k);
      }
    }
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
  void clearMemoryCache() {
    _memory.clear();
    _feedMemory.clear();
    _reactionMemory.clear();
    _savedMemory.clear();
  }

  @override
  Future<List<PostFeedItem>> listUserFeed({
    required String userId,
    int limit = 24,
    DateTime? cursorCreatedAt,
    String? cursorPostId,
    String? clusterId,
    bool onlyWithoutCluster = false,
    bool onlyWithMarker = false,
    bool excludeWithMarker = true,
    Set<String> filterSelectionKeys = const {},
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
        onlyWithMarker: onlyWithMarker,
        excludeWithMarker: excludeWithMarker,
        filterSelectionKeys: filterSelectionKeys,
      );

      if (items.isNotEmpty) return items;
    } catch (_) {
      // fallback ниже
    }

    if (filterSelectionKeys.isNotEmpty) return const [];

    return _listFallback(
      userId: uid,
      limit: limit,
      cursorCreatedAt: cursorCreatedAt,
      clusterId: clusterId,
      onlyWithoutCluster: onlyWithoutCluster,
      onlyWithMarker: onlyWithMarker,
      excludeWithMarker: excludeWithMarker,
    );
  }

  Future<List<PostFeedItem>> _listEnrichedCursor({
    required String userId,
    required int limit,
    DateTime? cursorCreatedAt,
    String? cursorPostId,
    String? clusterId,
    bool onlyWithoutCluster = false,
    bool onlyWithMarker = false,
    bool excludeWithMarker = true,
    Set<String> filterSelectionKeys = const {},
  }) async {
    final cid = clusterId?.trim();
    final hasCursor = cursorPostId != null && cursorCreatedAt != null && cursorPostId.trim().isNotEmpty;
    final filterKeys = filterSelectionKeys
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false)
      ..sort();
    final pArgs = <String, dynamic>{
      'p_user_id': userId,
      'p_limit': limit,
      'p_cursor_created_at': hasCursor ? cursorCreatedAt.toUtc().toIso8601String() : null,
      'p_cursor_id': hasCursor ? cursorPostId : null,
      'p_cluster_id': (!onlyWithoutCluster && cid != null && cid.isNotEmpty) ? cid : null,
      'p_only_without_cluster': onlyWithoutCluster,
      'p_exclude_with_marker': excludeWithMarker && !onlyWithMarker,
      'p_only_with_marker': onlyWithMarker,
      if (filterKeys.isNotEmpty) 'p_filter_selection_keys': filterKeys,
    };

    final res = await _client.rpc(
      'list_user_feed_enriched_cursor',
      params: <String, dynamic>{'p_args': pArgs},
    );

    return _consumeEnrichedRpc(
      res,
      onlyWithMarker: onlyWithMarker,
      excludeWithMarker: excludeWithMarker,
    );
  }

  Future<List<PostFeedItem>> _listFallback({
    required String userId,
    required int limit,
    DateTime? cursorCreatedAt,
    String? clusterId,
    bool onlyWithoutCluster = false,
    bool onlyWithMarker = false,
    bool excludeWithMarker = true,
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
      if (onlyWithMarker) {
        if (!post.hasMarker) continue;
      } else if (excludeWithMarker) {
        if (post.hasMarker) continue;
      }
      cachePost(post);
      items.add(PostFeedItem(post: post));
    }
    return items;
  }

  Future<List<PostFeedItem>> _consumeEnrichedRpc(
    dynamic res, {
    bool onlyWithMarker = false,
    bool excludeWithMarker = true,
  }) async {
    final bool? markerFilter = onlyWithMarker
        ? true
        : excludeWithMarker
        ? false
        : null;
    return PostFeedEnrichedParser.parse(
      res,
      onlyWithMarker: markerFilter,
      onItemParsed: (item) {
        cacheMyReaction(item.post.id, item.myReaction);
        cacheMySaved(item.post.id, item.mySaved);
        cacheFeedItem(item);
      },
    );
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
      final list = await _consumeEnrichedRpc(
        res,
        onlyWithMarker: false,
        excludeWithMarker: false,
      );
      if (list.isNotEmpty) {
        final item = await _enrichFollowingIfNeeded(list.first);
        cacheFeedItem(item);
        return item;
      }
    } catch (_) {
      // fallback
    }

    final post = await getById(id);
    if (post == null) return null;
    return PostFeedItem(post: post);
  }

  Future<PostFeedItem> _enrichFollowingIfNeeded(PostFeedItem item) async {
    if (item.myFollowingAuthor != null) return item;

    final uid = _client.auth.currentUser?.id.trim();
    final authorId = item.post.userId.trim();
    if (uid == null || uid.isEmpty || authorId.isEmpty || uid == authorId) {
      return item.copyWith(myFollowingAuthor: false);
    }

    try {
      final res = await _client.rpc('is_following_user', params: {'p_target': authorId});
      final following = res == true;
      return item.copyWith(myFollowingAuthor: following);
    } catch (_) {
      return item;
    }
  }

  @override
  Future<String?> setPostReaction(String postId, String? kind) async {
    final id = postId.trim();
    if (id.isEmpty) throw ArgumentError('postId');

    final normalized = kind?.trim();
    final payload = (normalized == null || normalized.isEmpty) ? null : normalized;
    if (payload != null && payload != 'like' && payload != 'dislike') {
      throw ArgumentError('kind');
    }

    final res = await _client.rpc(
      'set_post_reaction',
      params: {'p_post_id': id, 'p_kind': payload},
    );

    if (res is List && res.isNotEmpty) {
      final row = res.first;
      if (row is Map) {
        final k = row['kind'];
        if (k == null) return null;
        if (k is String) {
          final t = k.trim();
          if (t.isEmpty) return null;
          return t;
        }
      }
    }

    return payload;
  }

  @override
  Future<void> setPostSaved(String postId, bool saved) async {
    final id = postId.trim();
    if (id.isEmpty) throw ArgumentError('postId');

    await _client.rpc(
      saved ? 'save_post' : 'unsave_post',
      params: {'p_post_id': id},
    );
  }

  @override
  Future<void> setPostCluster(String postId, {String? clusterId}) async {
    final id = postId.trim();
    if (id.isEmpty) throw ArgumentError('postId');

    final normalized = clusterId?.trim();
    final payload = (normalized == null || normalized.isEmpty) ? null : normalized;

    await _client.from('posts').update({'cluster_id': payload}).eq('id', id);
  }

  @override
  Future<void> archivePost(String postId, {String? markerId}) async {
    final id = postId.trim();
    if (id.isEmpty) throw ArgumentError('postId');

    final mid = markerId?.trim();
    if (mid != null && mid.isNotEmpty) {
      await _client.from('markers').update({'is_archived': true}).eq('id', mid);
    } else {
      await _client.from('posts').update({'is_archived': true}).eq('id', id);
    }

    _memory.remove(id);
    _feedMemory.remove(id);
    _reactionMemory.remove(id);
    _savedMemory.remove(id);
  }

  @override
  Future<void> unarchivePost(String postId, {String? markerId}) async {
    final id = postId.trim();
    if (id.isEmpty) throw ArgumentError('postId');

    final mid = markerId?.trim();
    if (mid != null && mid.isNotEmpty) {
      await _client.from('markers').update({'is_archived': false}).eq('id', mid);
    } else {
      await _client.from('posts').update({'is_archived': false}).eq('id', id);
    }
  }

  @override
  Future<void> deletePost(String postId, {PostModel? cachedPost}) async {
    final id = postId.trim();
    if (id.isEmpty) throw ArgumentError('postId');

    final post = cachedPost ?? getCachedPostById(id);
    final mediaUrls = post?.sortedMedia.map((m) => m.url).where((u) => u.trim().isNotEmpty) ?? const [];

    await _deletePostStorageViaApi(id, mediaUrls);
    await _client.rpc('delete_owned_post', params: {'p_post_id': id});

    final uid = _client.auth.currentUser?.id.trim();
    if (uid != null && uid.isNotEmpty) {
      await _localCache.removePostFromUserFeeds(uid, id);
    }

    await _evictPostMediaFromCache(mediaUrls);

    _memory.remove(id);
    _feedMemory.remove(id);
    _reactionMemory.remove(id);
    _savedMemory.remove(id);
  }

  /// Пока пост ещё в БД — RLS `post_media_delete_own` разрешает удаление своих файлов.
  Future<void> _deletePostStorageViaApi(String postId, Iterable<String> mediaUrls) async {
    final paths = <String>{};

    for (final raw in mediaUrls) {
      final path = _storagePathFromPublicUrl(raw);
      if (path != null) paths.add(path);
    }

    try {
      final prefix = 'posts/$postId';
      final listing = await _client.storage.from('post_media').list(path: prefix);
      for (final entry in listing) {
        final name = entry.name.trim();
        if (name.isEmpty || entry.id == null) continue;
        paths.add('$prefix/$name');
      }
    } catch (_) {
      // list может не сработать — удаляем по URL из кэша
    }

    if (paths.isEmpty) return;

    try {
      await _client.storage.from('post_media').remove(paths.toList(growable: false));
    } catch (_) {
      // RPC дочистит storage best-effort
    }
  }

  String? _storagePathFromPublicUrl(String url) {
    final path = Uri.tryParse(url.split('?').first)?.path ?? '';
    const publicMarker = '/storage/v1/object/public/post_media/';
    final idx = path.indexOf(publicMarker);
    if (idx >= 0) {
      final objectPath = path.substring(idx + publicMarker.length).trim();
      return objectPath.isEmpty ? null : objectPath;
    }
    const shortMarker = '/object/public/post_media/';
    final shortIdx = path.indexOf(shortMarker);
    if (shortIdx >= 0) {
      final objectPath = path.substring(shortIdx + shortMarker.length).trim();
      return objectPath.isEmpty ? null : objectPath;
    }
    return null;
  }

  Future<void> _evictPostMediaFromCache(Iterable<String> urls) async {
    final seen = <String>{};
    for (final raw in urls) {
      final base = raw.split('?').first.trim();
      if (base.isEmpty || !seen.add(base)) continue;
      try {
        await CachedNetworkImage.evictFromCache(base);
      } catch (_) {
        // best effort
      }
    }
  }
}
