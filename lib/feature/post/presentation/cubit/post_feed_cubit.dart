import 'package:clover/feature/post/data/models/post_feed_item.dart';
import 'package:clover/feature/post/data/models/post_model.dart';
import 'package:clover/feature/post/data/repository/post_local_cache.dart';
import 'package:clover/feature/post/data/repository/post_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

/// Лента постов профиля: сначала local-кэш, затем remote (без сброса UI).
@injectable
class PostFeedCubit extends Cubit<PostFeedState> {
  PostFeedCubit(this._repository, this._localCache) : super(const PostFeedState.initial());

  final PostRepository _repository;
  final PostLocalCache _localCache;

  static const _pageSize = 24;

  String? _userId;
  String? _clusterId;
  bool _onlyWithoutCluster = false;
  bool _onlyWithMarker = false;
  bool _excludeWithMarker = true;
  Set<String> _filterSelectionKeys = const {};

  bool get _hasActiveFilters => _filterSelectionKeys.isNotEmpty;

  Future<void> load(
    String userId, {
    String? clusterId,
    bool onlyWithoutCluster = false,
    bool onlyWithMarker = false,
    bool excludeWithMarker = true,
    Set<String>? filterSelectionKeys,
  }) async {
    if (isClosed) return;
    final id = userId.trim();
    if (id.isEmpty) return;

    _userId = id;
    _clusterId = clusterId?.trim();
    _onlyWithoutCluster = onlyWithoutCluster;
    _onlyWithMarker = onlyWithMarker;
    _excludeWithMarker = excludeWithMarker;
    if (filterSelectionKeys != null) {
      _filterSelectionKeys = Set<String>.from(filterSelectionKeys);
    }

    if (!_hasActiveFilters) {
      final cached = await _localCache.readFeed(
        id,
        onlyWithMarker: onlyWithMarker,
        excludeWithMarker: excludeWithMarker,
      );
      if (cached != null && cached.isNotEmpty) {
        emit(
          PostFeedState.loaded(
            posts: cached,
            savedByPostId: const {},
            reactionsByPostId: const {},
            hasMore: true,
            isLoadingMore: false,
            isFromCache: true,
          ),
        );
      } else {
        emit(const PostFeedState.loading());
      }
    } else {
      emit(const PostFeedState.loading());
    }

    await _fetchRemote(reset: true);
  }

  Future<void> reload() async {
    final id = _userId;
    if (id == null || id.isEmpty) return;
    await load(
      id,
      clusterId: _clusterId,
      onlyWithoutCluster: _onlyWithoutCluster,
      onlyWithMarker: _onlyWithMarker,
      excludeWithMarker: _excludeWithMarker,
    );
  }

  Future<void> refresh() async {
    final id = _userId;
    if (id == null || id.isEmpty) return;
    final cur = state;
    if (cur is PostFeedLoaded) {
      emit(cur.copyWith(isRefreshing: true));
    }
    await _fetchRemote(reset: true);
  }

  /// Синхронизация реакции после экрана поста (оптимистичный лайк и т.д.).
  void patchPostReaction({required String postId, required String? reaction, PostModel? post}) {
    if (isClosed) return;
    final id = postId.trim();
    if (id.isEmpty) return;

    _repository.cacheMyReaction(id, reaction);

    final cur = state;
    if (cur is! PostFeedLoaded) return;

    final reactions = Map<String, String?>.from(cur.reactionsByPostId);
    reactions[id] = reaction;

    final posts = post == null
        ? cur.posts
        : cur.posts.map((p) => p.id == id ? post : p).toList(growable: false);

    emit(cur.copyWith(reactionsByPostId: reactions, posts: posts));
  }

  /// Синхронизация «сохранено» после экрана поста или ленты событий.
  void patchPostSaved({required String postId, required bool saved, PostModel? post}) {
    if (isClosed) return;
    final id = postId.trim();
    if (id.isEmpty) return;

    _repository.cacheMySaved(id, saved);

    final cur = state;
    if (cur is! PostFeedLoaded) return;

    final savedMap = Map<String, bool>.from(cur.savedByPostId);
    savedMap[id] = saved;

    final posts = post == null
        ? cur.posts
        : cur.posts.map((p) => p.id == id ? post : p).toList(growable: false);

    emit(cur.copyWith(savedByPostId: savedMap, posts: posts));
  }

  /// Синхронизация cluster_id после экрана поста.
  void patchPostCluster({required String postId, required PostModel post}) {
    if (isClosed) return;
    final id = postId.trim();
    if (id.isEmpty) return;

    final cur = state;
    if (cur is! PostFeedLoaded) return;

    final posts = cur.posts.map((p) => p.id == id ? post : p).toList(growable: false);
    emit(cur.copyWith(posts: posts));
  }

  /// Убрать пост из ленты после архивации или удаления на экране деталки.
  Future<void> removePost(String postId) async {
    if (isClosed) return;
    final id = postId.trim();
    if (id.isEmpty) return;

    final cur = state;
    if (cur is! PostFeedLoaded) return;

    final posts = cur.posts.where((p) => p.id != id).toList(growable: false);
    final reactions = Map<String, String?>.from(cur.reactionsByPostId)..remove(id);
    final saved = Map<String, bool>.from(cur.savedByPostId)..remove(id);
    emit(cur.copyWith(posts: posts, reactionsByPostId: reactions, savedByPostId: saved));

    final uid = _userId?.trim();
    if (uid != null && uid.isNotEmpty) {
      await _localCache.removePostFromUserFeeds(uid, id);
    }
  }

  String? myReactionFor(String postId) {
    final id = postId.trim();
    if (id.isEmpty) return null;

    // После лайка на экране поста лента может быть ещё без обновления — кэш приоритетнее.
    if (_repository.hasCachedMyReaction(id)) {
      return _repository.getCachedMyReaction(id);
    }

    final cur = state;
    if (cur is PostFeedLoaded && cur.reactionsByPostId.containsKey(id)) {
      return cur.reactionsByPostId[id];
    }
    return null;
  }

  PostFeedItem feedItemFor(PostModel post) {
    final id = post.id.trim();
    final cachedItem = _repository.getCachedFeedItem(id);
    final reaction = myReactionFor(id);
    final saved = _repository.hasCachedMySaved(id)
        ? _repository.getCachedMySaved(id)
        : (state is PostFeedLoaded ? ((state as PostFeedLoaded).savedByPostId[id] ?? false) : false);

    if (cachedItem != null) {
      return cachedItem.copyWith(
        post: _repository.getCachedPostById(id) ?? cachedItem.post,
        myReaction: reaction ?? cachedItem.myReaction,
        mySaved: saved,
      );
    }

    return PostFeedItem(
      post: _repository.getCachedPostById(id) ?? post,
      myReaction: reaction,
      mySaved: saved,
    );
  }

  Future<void> loadMore() async {
    final id = _userId;
    if (id == null) return;
    final cur = state;
    if (cur is! PostFeedLoaded || cur.isLoadingMore || !cur.hasMore || cur.posts.isEmpty) return;

    emit(cur.copyWith(isLoadingMore: true));
    try {
      final last = cur.posts.last;
      final more = await _repository.listUserFeed(
        userId: id,
        limit: _pageSize,
        cursorCreatedAt: last.createdAt,
        cursorPostId: last.id,
        clusterId: _clusterId,
        onlyWithoutCluster: _onlyWithoutCluster,
        onlyWithMarker: _onlyWithMarker,
        excludeWithMarker: _excludeWithMarker,
        filterSelectionKeys: _filterSelectionKeys,
      );
      if (isClosed) return;

      final merged = [...cur.posts, ...more.map((e) => e.post)];
      final saved = Map<String, bool>.from(cur.savedByPostId);
      final reactions = Map<String, String?>.from(cur.reactionsByPostId);
      for (final e in more) {
        saved[e.post.id] = e.mySaved;
        reactions[e.post.id] = e.myReaction;
      }

      emit(
        cur.copyWith(
          posts: merged,
          savedByPostId: saved,
          reactionsByPostId: reactions,
          hasMore: more.length == _pageSize,
          isLoadingMore: false,
          isFromCache: false,
          isRefreshing: false,
        ),
      );
      if (!_hasActiveFilters) {
        await _localCache.writeFeed(
          id,
          merged,
          onlyWithMarker: _onlyWithMarker,
          excludeWithMarker: _excludeWithMarker,
        );
      }
    } catch (_) {
      if (isClosed) return;
      emit(cur.copyWith(isLoadingMore: false, isRefreshing: false));
    }
  }

  Future<void> _fetchRemote({required bool reset}) async {
    final id = _userId;
    if (id == null) return;

    try {
      final enriched = await _repository.listUserFeed(
        userId: id,
        limit: _pageSize,
        clusterId: _clusterId,
        onlyWithoutCluster: _onlyWithoutCluster,
        onlyWithMarker: _onlyWithMarker,
        excludeWithMarker: _excludeWithMarker,
        filterSelectionKeys: _filterSelectionKeys,
      );
      if (isClosed) return;

      final posts = enriched.map((e) => e.post).toList(growable: false);
      final saved = {for (final e in enriched) e.post.id: e.mySaved};
      final reactions = {for (final e in enriched) e.post.id: e.myReaction};

      emit(
        PostFeedState.loaded(
          posts: posts,
          savedByPostId: saved,
          reactionsByPostId: reactions,
          hasMore: posts.length == _pageSize,
          isLoadingMore: false,
          isFromCache: false,
        ),
      );
      if (!_hasActiveFilters) {
        await _localCache.writeFeed(
          id,
          posts,
          onlyWithMarker: _onlyWithMarker,
          excludeWithMarker: _excludeWithMarker,
        );
      }
    } catch (e) {
      if (isClosed) return;
      final cur = state;
      if (cur is PostFeedLoaded && cur.posts.isNotEmpty) {
        emit(cur.copyWith(isRefreshing: false, isLoadingMore: false));
        return;
      }
      emit(PostFeedState.error('$e'));
    }
  }
}

sealed class PostFeedState {
  const PostFeedState();

  const factory PostFeedState.initial() = PostFeedInitial;
  const factory PostFeedState.loading() = PostFeedLoading;
  const factory PostFeedState.loaded({
    required List<PostModel> posts,
    required Map<String, bool> savedByPostId,
    required Map<String, String?> reactionsByPostId,
    required bool hasMore,
    required bool isLoadingMore,
    bool isFromCache,
    bool isRefreshing,
  }) = PostFeedLoaded;
  const factory PostFeedState.error(String message) = PostFeedError;
}

final class PostFeedInitial extends PostFeedState {
  const PostFeedInitial();
}

final class PostFeedLoading extends PostFeedState {
  const PostFeedLoading();
}

final class PostFeedLoaded extends PostFeedState {
  const PostFeedLoaded({
    required this.posts,
    required this.savedByPostId,
    required this.reactionsByPostId,
    required this.hasMore,
    required this.isLoadingMore,
    this.isFromCache = false,
    this.isRefreshing = false,
  });

  final List<PostModel> posts;
  final Map<String, bool> savedByPostId;
  final Map<String, String?> reactionsByPostId;
  final bool hasMore;
  final bool isLoadingMore;
  final bool isFromCache;
  final bool isRefreshing;

  PostFeedLoaded copyWith({
    List<PostModel>? posts,
    Map<String, bool>? savedByPostId,
    Map<String, String?>? reactionsByPostId,
    bool? hasMore,
    bool? isLoadingMore,
    bool? isFromCache,
    bool? isRefreshing,
  }) {
    return PostFeedLoaded(
      posts: posts ?? this.posts,
      savedByPostId: savedByPostId ?? this.savedByPostId,
      reactionsByPostId: reactionsByPostId ?? this.reactionsByPostId,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isFromCache: isFromCache ?? this.isFromCache,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }
}

final class PostFeedError extends PostFeedState {
  const PostFeedError(this.message);
  final String message;
}
