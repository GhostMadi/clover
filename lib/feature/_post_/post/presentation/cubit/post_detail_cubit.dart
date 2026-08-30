import 'package:clover/feature/_cluster_/cluster/presentation/cluster_list_refresh.dart';
import 'package:clover/feature/_catalog_/marker_tags/data/repository/marker_tags_repository.dart';
import 'package:clover/feature/_post_/post/data/models/post_marker_summary.dart';
import 'package:clover/feature/_post_/post/data/models/post_feed_item.dart';
import 'package:clover/feature/_post_/post/data/models/post_model.dart';
import 'package:clover/feature/_post_/post/data/models/post_reaction_math.dart';
import 'package:clover/feature/_post_/post/data/repository/post_repository.dart';
import 'package:clover/feature/_catalog_/social_graph/data/repository/social_graph_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

/// Экран одного поста: мгновенно из [initialPost] / кэша ленты; RPC только без seed или по refresh/reload.
@injectable
class PostDetailCubit extends Cubit<PostDetailState> {
  PostDetailCubit(this._repository, this._socialGraph, this._markerTags)
      : super(const PostDetailState.initial());

  final PostRepository _repository;
  final SocialGraphRepository _socialGraph;
  final MarkerTagsRepository _markerTags;

  String? _postId;
  PostModel? _initialPost;
  String? _initialMyReaction;
  String? _initialAuthorUsername;
  String? _initialAuthorAvatarUrl;
  PostMarkerSummary? _initialMarker;
  bool _reactionRequestInFlight = false;
  bool _followRequestInFlight = false;
  bool _saveRequestInFlight = false;
  bool _clusterRequestInFlight = false;

  /// [initialPost] — данные от родителя (лента); [initialMyReaction] — лайк/дизлайк без второго запроса.
  Future<void> load(
    String postId, {
    PostModel? initialPost,
    PostMarkerSummary? initialMarker,
    String? initialMyReaction,
    String? initialAuthorUsername,
    String? initialAuthorAvatarUrl,
  }) async {
    if (isClosed) return;
    final id = postId.trim();
    if (id.isEmpty) {
      emit(const PostDetailState.error('Некорректный id поста'));
      return;
    }

    _postId = id;
    final cachedItem = _repository.getCachedFeedItem(id);
    _initialPost = initialPost ?? cachedItem?.post ?? _repository.getCachedPostById(id);
    _initialMarker = initialMarker ?? cachedItem?.marker ?? _initialMarker;
    _initialMyReaction = _resolveInitialReaction(initialMyReaction ?? cachedItem?.myReaction, id);
    _initialAuthorUsername = _trimOrNull(initialAuthorUsername ?? cachedItem?.authorUsername);
    _initialAuthorAvatarUrl = _trimOrNull(initialAuthorAvatarUrl ?? cachedItem?.authorAvatarUrl);

    final seed = _initialPost;
    if (seed != null) {
      final item = PostFeedItem(
        post: seed,
        myReaction: _initialMyReaction,
        authorUsername: _initialAuthorUsername,
        authorAvatarUrl: _initialAuthorAvatarUrl,
        marker: _initialMarker,
        mySaved: _resolveInitialSaved(cachedItem?.mySaved, id),
        myFollowingAuthor: cachedItem?.myFollowingAuthor,
        profileFilters: cachedItem?.profileFilters ?? const [],
      );
      _repository.cacheFeedItem(item);
      emit(PostDetailState.loaded(item, isFromCache: true));

      await _fetchRemote();
      return;
    }

    emit(const PostDetailState.loading());
    await _fetchRemote();
  }

  Future<void> reload() async {
    final id = _postId;
    if (id == null || id.isEmpty) return;

    final cur = state;
    if (cur is PostDetailLoaded) {
      emit(cur.copyWith(isRefreshing: true));
    } else if (_initialPost != null) {
      final cachedItem = _repository.getCachedFeedItem(_postId ?? '');
      emit(
        PostDetailState.loaded(
          PostFeedItem(
            post: _initialPost!,
            myReaction: _initialMyReaction,
            authorUsername: _initialAuthorUsername,
            authorAvatarUrl: _initialAuthorAvatarUrl,
            marker: _initialMarker,
            profileFilters: cachedItem?.profileFilters ?? const [],
          ),
          isFromCache: true,
          isRefreshing: true,
        ),
      );
    } else {
      emit(const PostDetailState.loading());
    }
    await _fetchRemote();
  }

  Future<void> refresh() async {
    final id = _postId;
    if (id == null || id.isEmpty) return;

    final cur = state;
    if (cur is PostDetailLoaded) {
      emit(cur.copyWith(isRefreshing: true));
    }
    await _fetchRemote();
  }

  Future<void> toggleLike() async {
    final cur = state;
    if (cur is! PostDetailLoaded) return;
    final next = cur.item.isLiked ? null : 'like';
    await _setReaction(next);
  }

  Future<void> toggleDislike() async {
    final cur = state;
    if (cur is! PostDetailLoaded) return;
    final next = cur.item.isDisliked ? null : 'dislike';
    await _setReaction(next);
  }

  Future<void> toggleSave() async {
    final cur = state;
    if (cur is! PostDetailLoaded) return;

    final id = _postId;
    if (id == null || id.isEmpty) return;

    final snapshot = cur.item;
    final wasSaved = snapshot.mySaved;
    final nextSaved = !wasSaved;
    final optimistic = snapshot.copyWith(mySaved: nextSaved);

    _repository.cacheMySaved(id, nextSaved);
    emit(cur.copyWith(item: optimistic));

    _saveRequestInFlight = true;
    try {
      await _repository.setPostSaved(id, nextSaved);
      if (isClosed) return;

      final latest = state;
      if (latest is! PostDetailLoaded) return;
      if (latest.item.mySaved != nextSaved) return;

      _repository.cacheFeedItem(latest.item);
    } catch (_) {
      if (isClosed) return;

      final latest = state;
      if (latest is! PostDetailLoaded) return;
      if (latest.item.mySaved != nextSaved) return;

      _repository.cacheMySaved(id, wasSaved);
      _repository.cachePost(snapshot.post);
      emit(latest.copyWith(item: snapshot));
    } finally {
      _saveRequestInFlight = false;
    }
  }

  Future<void> toggleFollow() async {
    final cur = state;
    if (cur is! PostDetailLoaded || cur.isFollowUpdating) return;

    final authorId = cur.item.post.userId.trim();
    if (authorId.isEmpty) return;

    final snapshot = cur.item;
    final wasFollowing = snapshot.myFollowingAuthor ?? false;
    final next = !wasFollowing;

    emit(cur.copyWith(item: snapshot.copyWith(myFollowingAuthor: next), isFollowUpdating: true));

    _followRequestInFlight = true;
    try {
      if (next) {
        await _socialGraph.followUser(authorId);
      } else {
        await _socialGraph.unfollowUser(authorId);
      }
      if (isClosed) return;

      final latest = state;
      if (latest is! PostDetailLoaded) return;
      if (latest.item.myFollowingAuthor != next) return;

      emit(latest.copyWith(isFollowUpdating: false));
    } catch (_) {
      if (isClosed) return;

      final latest = state;
      if (latest is! PostDetailLoaded) return;
      if (latest.item.myFollowingAuthor != next) return;

      emit(
        latest.copyWith(
          item: snapshot,
          isFollowUpdating: false,
        ),
      );
    } finally {
      _followRequestInFlight = false;
    }
  }

  /// Привязать пост к кластеру или отвязать ([clusterId] = null).
  Future<void> setPostCluster(String? clusterId) async {
    final cur = state;
    if (cur is! PostDetailLoaded) return;

    final id = _postId;
    if (id == null || id.isEmpty) return;

    final snapshot = cur.item;
    final currentCluster = snapshot.post.clusterId?.trim();
    final normalized = clusterId?.trim();
    final nextCluster = (normalized == null || normalized.isEmpty) ? null : normalized;

    if (currentCluster == nextCluster) return;

    final optimisticPost = nextCluster == null
        ? snapshot.post.copyWith(clearClusterId: true)
        : snapshot.post.copyWith(clusterId: nextCluster);
    final optimistic = snapshot.copyWith(post: optimisticPost);

    emit(cur.copyWith(item: optimistic));

    _clusterRequestInFlight = true;
    try {
      await _repository.setPostCluster(id, clusterId: nextCluster);
      if (isClosed) return;

      _repository.cachePost(optimisticPost);
      _repository.cacheFeedItem(optimistic);

      clusterListRefreshTick.value++;
    } catch (_) {
      if (isClosed) return;

      final latest = state;
      if (latest is! PostDetailLoaded) return;
      if (latest.item.post.clusterId != nextCluster) return;

      _repository.cachePost(snapshot.post);
      _repository.cacheFeedItem(snapshot);
      emit(latest.copyWith(item: snapshot));
      rethrow;
    } finally {
      _clusterRequestInFlight = false;
    }
  }

  /// Архивировать текущий пост или ивент (маркер).
  Future<void> archivePost() async {
    final cur = state;
    if (cur is! PostDetailLoaded) return;

    final id = _postId;
    if (id == null || id.isEmpty) return;

    final markerId = cur.item.marker?.id.trim() ?? cur.item.post.markerId?.trim();
    await _repository.archivePost(id, markerId: markerId);
    clusterListRefreshTick.value++;
  }

  /// Разархивировать текущий пост или ивент (маркер).
  Future<void> unarchivePost({required bool isEvent}) async {
    final cur = state;
    if (cur is! PostDetailLoaded) return;

    final id = _postId;
    if (id == null || id.isEmpty) return;

    final markerId = isEvent ? cur.item.marker?.id.trim() ?? cur.item.post.markerId?.trim() : null;
    await _repository.unarchivePost(id, markerId: markerId);
    clusterListRefreshTick.value++;
  }

  /// Безвозвратно удалить текущий пост или ивент.
  Future<void> deletePost() async {
    final cur = state;
    if (cur is! PostDetailLoaded) return;

    final id = _postId;
    if (id == null || id.isEmpty) return;

    await _repository.deletePost(id, cachedPost: cur.item.post);
    clusterListRefreshTick.value++;
  }

  /// Текущая реакция для синхронизации с лентой профиля при выходе.
  PostFeedItem? get currentItem {
    final cur = state;
    return cur is PostDetailLoaded ? cur.item : null;
  }

  void patchCommentsCount(int count) {
    final cur = state;
    if (cur is! PostDetailLoaded) return;
    if (cur.item.post.commentsCount == count) return;
    final next = cur.item.copyWith(post: cur.item.post.copyWith(commentsCount: count));
    _repository.cachePost(next.post);
    _repository.cacheFeedItem(next);
    emit(cur.copyWith(item: next));
  }

  void patchSendsCount(int count) {
    final cur = state;
    if (cur is! PostDetailLoaded) return;
    if (cur.item.post.sendsCount == count) return;
    final next = cur.item.copyWith(post: cur.item.post.copyWith(sendsCount: count));
    _repository.cachePost(next.post);
    _repository.cacheFeedItem(next);
    emit(cur.copyWith(item: next));
  }

  Future<void> _setReaction(String? next) async {
    final cur = state;
    if (cur is! PostDetailLoaded) return;

    final id = _postId;
    if (id == null || id.isEmpty) return;

    final snapshot = cur.item;
    final from = snapshot.myReaction;
    final normalized = _normalizeReaction(next);
    if (from == normalized) return;

    final optimisticPost = PostReactionMath.apply(
      post: snapshot.post,
      from: from,
      to: normalized,
    );
    final optimistic = snapshot.copyWith(
      post: optimisticPost,
      myReaction: normalized,
      clearMyReaction: normalized == null,
    );

    _initialMyReaction = normalized;
    _repository.cacheMyReaction(id, normalized);
    _repository.cachePost(optimisticPost);
    emit(cur.copyWith(item: optimistic));

    _reactionRequestInFlight = true;
    try {
      final confirmed = await _repository.setPostReaction(id, normalized);
      if (isClosed) return;

      final latest = state;
      if (latest is! PostDetailLoaded) return;
      if (latest.item.myReaction != normalized) return;

      final confirmedReaction = _normalizeReaction(confirmed);
      _repository.cacheMyReaction(id, confirmedReaction);
      _initialMyReaction = confirmedReaction;

      if (confirmedReaction == normalized) return;

      final reconciledPost = PostReactionMath.apply(
        post: snapshot.post,
        from: from,
        to: confirmedReaction,
      );
      final reconciled = snapshot.copyWith(
        post: reconciledPost,
        myReaction: confirmedReaction,
        clearMyReaction: confirmedReaction == null,
      );
      _repository.cachePost(reconciledPost);
      emit(latest.copyWith(item: reconciled));
    } catch (_) {
      if (isClosed) return;

      final latest = state;
      if (latest is! PostDetailLoaded) return;
      if (latest.item.myReaction != normalized) return;

      _initialMyReaction = from;
      _repository.cacheMyReaction(id, from);
      _repository.cachePost(snapshot.post);
      emit(latest.copyWith(item: snapshot));
    } finally {
      _reactionRequestInFlight = false;
    }
  }

  Future<void> _fetchRemote() async {
    final id = _postId;
    if (id == null) return;

    try {
      final fetched = await _repository.getPostEnriched(id);
      if (isClosed) return;

      if (fetched == null) {
        final cur = state;
        if (cur is PostDetailLoaded) {
          emit(cur.copyWith(isRefreshing: false));
          return;
        }
        emit(const PostDetailState.error('Пост недоступен'));
        return;
      }

      final item = await _withMarkerTags(fetched);
      if (isClosed) return;

      _repository.cacheMyReaction(id, item.myReaction);
      _repository.cacheMySaved(id, item.mySaved);

      final cur = state;
      if (cur is PostDetailLoaded) {
        var merged = item;
        var keepLocal = false;

        if (_reactionRequestInFlight && cur.item.myReaction != item.myReaction) {
          merged = merged.copyWith(
            post: cur.item.post,
            myReaction: cur.item.myReaction,
            clearMyReaction: cur.item.myReaction == null,
          );
          keepLocal = true;
        }

        if (_followRequestInFlight && cur.item.myFollowingAuthor != item.myFollowingAuthor) {
          merged = merged.copyWith(myFollowingAuthor: cur.item.myFollowingAuthor);
          keepLocal = true;
        }

        if (_clusterRequestInFlight && cur.item.post.clusterId != item.post.clusterId) {
          merged = merged.copyWith(post: cur.item.post);
          keepLocal = true;
        }

        if (_saveRequestInFlight && cur.item.mySaved != item.mySaved) {
          merged = merged.copyWith(
            post: cur.item.post,
            mySaved: cur.item.mySaved,
          );
          keepLocal = true;
        }

        if (keepLocal) {
          emit(
            PostDetailState.loaded(
              merged,
              isFromCache: false,
              isRefreshing: false,
              isFollowUpdating: cur.isFollowUpdating,
            ),
          );
          return;
        }

        final mergedWithAuthor = item.copyWith(
          authorUsername: item.authorUsername ?? cur.item.authorUsername,
          authorAvatarUrl: item.authorAvatarUrl ?? cur.item.authorAvatarUrl,
          marker: item.marker ?? cur.item.marker,
        );
        emit(
          PostDetailState.loaded(
            mergedWithAuthor,
            isFromCache: false,
            isRefreshing: false,
            isFollowUpdating: cur.isFollowUpdating,
          ),
        );
        _initialMyReaction = mergedWithAuthor.myReaction;
        _initialMarker = mergedWithAuthor.marker ?? _initialMarker;
        _initialAuthorUsername = mergedWithAuthor.authorUsername ?? _initialAuthorUsername;
        _initialAuthorAvatarUrl = mergedWithAuthor.authorAvatarUrl ?? _initialAuthorAvatarUrl;
        _repository.cacheFeedItem(mergedWithAuthor);
        _repository.cachePost(mergedWithAuthor.post);
        return;
      }

      emit(
        PostDetailState.loaded(
          item,
          isFromCache: false,
          isRefreshing: false,
        ),
      );
      _initialMyReaction = item.myReaction;
      _initialMarker = item.marker ?? _initialMarker;
      _initialAuthorUsername = item.authorUsername ?? _initialAuthorUsername;
      _initialAuthorAvatarUrl = item.authorAvatarUrl ?? _initialAuthorAvatarUrl;
      _repository.cacheFeedItem(item);
      _repository.cachePost(item.post);
    } catch (e) {
      if (isClosed) return;
      final cur = state;
      if (cur is PostDetailLoaded) {
        emit(cur.copyWith(isRefreshing: false));
        return;
      }
      emit(PostDetailState.error('$e'));
    }
  }

  Future<PostFeedItem> _withMarkerTags(PostFeedItem item) async {
    final marker = item.marker;
    if (marker == null || marker.tags.isNotEmpty) return item;

    try {
      final tags = await _markerTags.listForMarker(marker.id);
      if (tags.isEmpty) return item;
      return item.copyWith(marker: marker.copyWith(tags: tags));
    } catch (_) {
      return item;
    }
  }

  String? _resolveInitialReaction(String? fromNav, String postId) {
    if (_repository.hasCachedMyReaction(postId)) {
      return _repository.getCachedMyReaction(postId);
    }
    return _normalizeReaction(fromNav);
  }

  bool _resolveInitialSaved(bool? fromNav, String postId) {
    if (_repository.hasCachedMySaved(postId)) {
      return _repository.getCachedMySaved(postId);
    }
    return fromNav ?? false;
  }

  static String? _trimOrNull(String? raw) {
    final v = raw?.trim();
    return v != null && v.isNotEmpty ? v : null;
  }

  static String? _normalizeReaction(String? raw) {
    final v = raw?.trim();
    if (v == null || v.isEmpty) return null;
    if (v == 'like' || v == 'dislike') return v;
    return null;
  }
}

sealed class PostDetailState {
  const PostDetailState();

  const factory PostDetailState.initial() = PostDetailInitial;
  const factory PostDetailState.loading() = PostDetailLoading;
  const factory PostDetailState.loaded(
    PostFeedItem item, {
    bool isFromCache,
    bool isRefreshing,
    bool isFollowUpdating,
  }) = PostDetailLoaded;
  const factory PostDetailState.error(String message) = PostDetailError;
}

final class PostDetailInitial extends PostDetailState {
  const PostDetailInitial();
}

final class PostDetailLoading extends PostDetailState {
  const PostDetailLoading();
}

final class PostDetailLoaded extends PostDetailState {
  const PostDetailLoaded(
    this.item, {
    this.isFromCache = false,
    this.isRefreshing = false,
    this.isFollowUpdating = false,
  });

  final PostFeedItem item;
  final bool isFromCache;
  final bool isRefreshing;
  final bool isFollowUpdating;

  PostDetailLoaded copyWith({
    PostFeedItem? item,
    bool? isFromCache,
    bool? isRefreshing,
    bool? isFollowUpdating,
  }) {
    return PostDetailLoaded(
      item ?? this.item,
      isFromCache: isFromCache ?? this.isFromCache,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isFollowUpdating: isFollowUpdating ?? this.isFollowUpdating,
    );
  }
}

final class PostDetailError extends PostDetailState {
  const PostDetailError(this.message);
  final String message;
}
