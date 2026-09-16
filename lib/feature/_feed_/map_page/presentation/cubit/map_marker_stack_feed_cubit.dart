import 'package:clover/feature/_feed_/map_page/data/models/map_marker_item.dart';
import 'package:clover/feature/_post_/post/data/models/post_feed_item.dart';
import 'package:clover/feature/_post_/post/data/models/post_reaction_math.dart';
import 'package:clover/feature/_post_/post/data/repository/post_repository.dart';
import 'package:clover/feature/_catalog_/social_graph/data/repository/social_graph_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum MapMarkerStackFollowButton { subscribe, unsubscribe }

/// Лента постов стопки маркеров (реакции / подписка как в events feed).
class MapMarkerStackFeedCubit extends Cubit<MapMarkerStackFeedState> {
  MapMarkerStackFeedCubit(this._postRepository, this._socialGraph, this._client)
      : super(const MapMarkerStackFeedState.initial());

  final PostRepository _postRepository;
  final SocialGraphRepository _socialGraph;
  final SupabaseClient _client;

  final Set<String> _sessionFollowToggledAuthorIds = {};
  final Set<String> _followUpdatingAuthorIds = {};

  String? get _currentUserId {
    final id = _client.auth.currentUser?.id.trim();
    return id != null && id.isNotEmpty ? id : null;
  }

  Future<void> load(List<MapMarkerItem> markers) async {
    emit(const MapMarkerStackFeedState.loading());
    try {
      final postIds = [
        for (final marker in markers)
          if ((marker.postId?.trim().isNotEmpty) ?? false) marker.postId!.trim(),
      ];
      final items = await _postRepository.getPostsEnriched(postIds);
      if (isClosed) return;
      emit(MapMarkerStackFeedState.loaded(items: items));
    } catch (error) {
      if (isClosed) return;
      emit(MapMarkerStackFeedState.error(message: error.toString()));
    }
  }

  MapMarkerStackFollowButton? followButtonFor(PostFeedItem item) {
    final uid = _currentUserId;
    if (uid == null) return null;

    final authorId = item.post.userId.trim();
    if (authorId.isEmpty || authorId == uid) return null;

    final following = item.myFollowingAuthor ?? false;
    final toggledInSession = _sessionFollowToggledAuthorIds.contains(authorId);

    if (following && !toggledInSession) return null;
    return following ? MapMarkerStackFollowButton.unsubscribe : MapMarkerStackFollowButton.subscribe;
  }

  bool isFollowUpdating(PostFeedItem item) {
    return _followUpdatingAuthorIds.contains(item.post.userId.trim());
  }

  Future<void> toggleFollow(PostFeedItem item) async {
    final authorId = item.post.userId.trim();
    if (authorId.isEmpty || isFollowUpdating(item)) return;

    final uid = _currentUserId;
    if (uid == null || uid == authorId) return;

    final wasFollowing = item.myFollowingAuthor ?? false;
    final nextFollowing = !wasFollowing;

    _sessionFollowToggledAuthorIds.add(authorId);
    _followUpdatingAuthorIds.add(authorId);
    _patchAuthorFollowing(authorId, nextFollowing);

    try {
      if (nextFollowing) {
        await _socialGraph.followUser(authorId);
      } else {
        await _socialGraph.unfollowUser(authorId);
      }
    } catch (_) {
      if (isClosed) return;
      _sessionFollowToggledAuthorIds.remove(authorId);
      _patchAuthorFollowing(authorId, wasFollowing);
    } finally {
      _followUpdatingAuthorIds.remove(authorId);
      if (!isClosed) _emitLoadedSnapshot();
    }
  }

  Future<void> toggleLike(PostFeedItem item) async {
    await _setReaction(item, item.isLiked ? null : 'like');
  }

  Future<void> toggleDislike(PostFeedItem item) async {
    await _setReaction(item, item.isDisliked ? null : 'dislike');
  }

  Future<void> toggleSave(PostFeedItem item) async {
    final postId = item.post.id.trim();
    if (postId.isEmpty) return;

    final wasSaved = item.mySaved;
    final nextSaved = !wasSaved;
    final optimistic = item.copyWith(mySaved: nextSaved);

    _postRepository.cacheMySaved(postId, nextSaved);
    _postRepository.cacheFeedItem(optimistic);
    _patchPostItem(optimistic);

    try {
      await _postRepository.setPostSaved(postId, nextSaved);
    } catch (_) {
      if (isClosed) return;
      final current = _findItem(postId);
      if (current?.mySaved != nextSaved) return;
      _postRepository.cacheMySaved(postId, wasSaved);
      _postRepository.cacheFeedItem(item);
      _patchPostItem(item);
    }
  }

  void patchCommentsCount(String postId, int count) {
    final id = postId.trim();
    if (id.isEmpty) return;
    final cur = state;
    if (cur is! MapMarkerStackFeedLoaded) return;

    emit(
      MapMarkerStackFeedLoaded(
        items: [
          for (final feedItem in cur.items)
            if (feedItem.post.id == id)
              feedItem.copyWith(post: feedItem.post.copyWith(commentsCount: count))
            else
              feedItem,
        ],
      ),
    );
  }

  void patchSendsCount(String postId, int count) {
    final id = postId.trim();
    if (id.isEmpty) return;
    final cur = state;
    if (cur is! MapMarkerStackFeedLoaded) return;

    emit(
      MapMarkerStackFeedLoaded(
        items: [
          for (final feedItem in cur.items)
            if (feedItem.post.id == id)
              feedItem.copyWith(post: feedItem.post.copyWith(sendsCount: count))
            else
              feedItem,
        ],
      ),
    );
  }

  Future<void> _setReaction(PostFeedItem item, String? next) async {
    final postId = item.post.id.trim();
    if (postId.isEmpty) return;

    final from = item.myReaction;
    final normalized = _normalizeReaction(next);
    if (from == normalized) return;

    final optimisticPost = PostReactionMath.apply(post: item.post, from: from, to: normalized);
    final optimistic = item.copyWith(
      post: optimisticPost,
      myReaction: normalized,
      clearMyReaction: normalized == null,
    );

    _postRepository.cacheMyReaction(postId, normalized);
    _postRepository.cacheFeedItem(optimistic);
    _patchPostItem(optimistic);

    try {
      final confirmed = await _postRepository.setPostReaction(postId, normalized);
      if (isClosed) return;

      final current = _findItem(postId);
      if (current == null || current.myReaction != normalized) return;

      final confirmedReaction = _normalizeReaction(confirmed);
      _postRepository.cacheMyReaction(postId, confirmedReaction);
      if (confirmedReaction == normalized) return;

      final reconciledPost = PostReactionMath.apply(post: item.post, from: from, to: confirmedReaction);
      final reconciled = item.copyWith(
        post: reconciledPost,
        myReaction: confirmedReaction,
        clearMyReaction: confirmedReaction == null,
      );
      _postRepository.cacheFeedItem(reconciled);
      _patchPostItem(reconciled);
    } catch (_) {
      if (isClosed) return;
      final current = _findItem(postId);
      if (current?.myReaction != normalized) return;
      _postRepository.cacheMyReaction(postId, from);
      _postRepository.cacheFeedItem(item);
      _patchPostItem(item);
    }
  }

  String? _normalizeReaction(String? value) {
    final v = value?.trim();
    if (v == 'like' || v == 'dislike') return v;
    return null;
  }

  PostFeedItem? _findItem(String postId) {
    final cur = state;
    if (cur is! MapMarkerStackFeedLoaded) return null;
    for (final feedItem in cur.items) {
      if (feedItem.post.id == postId) return feedItem;
    }
    return null;
  }

  void _patchPostItem(PostFeedItem item) {
    final cur = state;
    if (cur is! MapMarkerStackFeedLoaded) return;

    emit(
      MapMarkerStackFeedLoaded(
        items: [
          for (final feedItem in cur.items)
            if (feedItem.post.id == item.post.id) item else feedItem,
        ],
      ),
    );
  }

  void _patchAuthorFollowing(String authorId, bool following) {
    final cur = state;
    if (cur is! MapMarkerStackFeedLoaded) return;

    emit(
      MapMarkerStackFeedLoaded(
        items: [
          for (final feedItem in cur.items)
            if (feedItem.post.userId.trim() == authorId)
              feedItem.copyWith(myFollowingAuthor: following)
            else
              feedItem,
        ],
      ),
    );
  }

  void _emitLoadedSnapshot() {
    final cur = state;
    if (cur is MapMarkerStackFeedLoaded) {
      emit(MapMarkerStackFeedLoaded(items: cur.items));
    }
  }
}

sealed class MapMarkerStackFeedState {
  const MapMarkerStackFeedState();

  const factory MapMarkerStackFeedState.initial() = MapMarkerStackFeedInitial;
  const factory MapMarkerStackFeedState.loading() = MapMarkerStackFeedLoading;
  const factory MapMarkerStackFeedState.loaded({required List<PostFeedItem> items}) = MapMarkerStackFeedLoaded;
  const factory MapMarkerStackFeedState.error({required String message}) = MapMarkerStackFeedError;
}

final class MapMarkerStackFeedInitial extends MapMarkerStackFeedState {
  const MapMarkerStackFeedInitial();
}

final class MapMarkerStackFeedLoading extends MapMarkerStackFeedState {
  const MapMarkerStackFeedLoading();
}

final class MapMarkerStackFeedLoaded extends MapMarkerStackFeedState {
  const MapMarkerStackFeedLoaded({required this.items});

  final List<PostFeedItem> items;
}

final class MapMarkerStackFeedError extends MapMarkerStackFeedState {
  const MapMarkerStackFeedError({required this.message});

  final String message;
}
