import 'package:clover/feature/events_page/data/models/events_filter.dart';
import 'package:clover/feature/events_page/data/repository/events_feed_repository.dart';
import 'package:clover/feature/post/data/models/post_feed_item.dart';
import 'package:clover/feature/post/data/models/post_reaction_math.dart';
import 'package:clover/feature/post/data/repository/post_repository.dart';
import 'package:clover/feature/social_graph/data/repository/social_graph_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'events_feed_cubit.freezed.dart';

enum EventsFeedFollowButton { subscribe, unsubscribe }

@injectable
class EventsFeedCubit extends Cubit<EventsFeedState> {
  EventsFeedCubit(this._repository, this._postRepository, this._socialGraph, this._client)
    : super(const EventsFeedState.initial());

  final EventsFeedRepository _repository;
  final PostRepository _postRepository;
  final SocialGraphRepository _socialGraph;
  final SupabaseClient _client;

  static const _pageSize = 24;

  EventsFilter _filter = EventsFilter.defaults;

  /// Авторы, на которых подписались/отписались в этой сессии ленты.
  final Set<String> _sessionFollowToggledAuthorIds = {};
  final Set<String> _followUpdatingAuthorIds = {};

  String? get _currentUserId {
    final id = _client.auth.currentUser?.id.trim();
    return id != null && id.isNotEmpty ? id : null;
  }

  /// `null` — кнопку не показываем (свой пост или уже были подписаны до действия в ленте).
  EventsFeedFollowButton? followButtonFor(PostFeedItem item) {
    final uid = _currentUserId;
    if (uid == null) return null;

    final authorId = item.post.userId.trim();
    if (authorId.isEmpty || authorId == uid) return null;

    final following = item.myFollowingAuthor ?? false;
    final toggledInSession = _sessionFollowToggledAuthorIds.contains(authorId);

    if (following && !toggledInSession) return null;
    return following ? EventsFeedFollowButton.unsubscribe : EventsFeedFollowButton.subscribe;
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

  void _patchAuthorFollowing(String authorId, bool following) {
    final cur = state.mapOrNull(loaded: (s) => s);
    if (cur == null) return;

    emit(
      cur.copyWith(
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
    final cur = state.mapOrNull(loaded: (s) => s);
    if (cur != null) emit(cur.copyWith());
  }

  Future<void> toggleLike(PostFeedItem item) async {
    await _setReaction(item, item.isLiked ? null : 'like');
  }

  Future<void> toggleDislike(PostFeedItem item) async {
    await _setReaction(item, item.isDisliked ? null : 'dislike');
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

    final cur = state.mapOrNull(loaded: (s) => s);
    if (cur == null) return;

    emit(
      cur.copyWith(
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

    final cur = state.mapOrNull(loaded: (s) => s);
    if (cur == null) return;

    emit(
      cur.copyWith(
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

  PostFeedItem? _findItem(String postId) {
    final cur = state.mapOrNull(loaded: (s) => s);
    if (cur == null) return null;
    for (final feedItem in cur.items) {
      if (feedItem.post.id == postId) return feedItem;
    }
    return null;
  }

  void _patchPostItem(PostFeedItem item) {
    final cur = state.mapOrNull(loaded: (s) => s);
    if (cur == null) return;

    emit(
      cur.copyWith(
        items: [
          for (final feedItem in cur.items)
            if (feedItem.post.id == item.post.id) item else feedItem,
        ],
      ),
    );
  }

  Future<void> load(EventsFilter filter) async {
    if (isClosed) return;
    _filter = filter;
    emit(EventsFeedState.loading(filter: filter));
    await _fetch(reset: true);
  }

  Future<void> refresh() async {
    if (isClosed) return;
    state.mapOrNull(loaded: (cur) => emit(cur.copyWith(isRefreshing: true)));
    await _fetch(reset: true);
  }

  Future<void> loadMore() async {
    final cur = state.mapOrNull(loaded: (s) => s);
    if (cur == null || cur.isLoadingMore || !cur.hasMore || cur.items.isEmpty) return;

    emit(cur.copyWith(isLoadingMore: true));
    try {
      final page = await _repository.listFeed(filter: _filter, limit: _pageSize, cursorItem: cur.items.last);
      if (isClosed) return;

      if (page.items.isEmpty) {
        emit(cur.copyWith(isLoadingMore: false, isRefreshing: false, hasMore: false));
        return;
      }

      final existingIds = cur.items.map((e) => e.post.id).toSet();
      final newItems = page.items.where((item) => existingIds.add(item.post.id)).toList(growable: false);

      if (newItems.isEmpty) {
        emit(cur.copyWith(isLoadingMore: false, isRefreshing: false, hasMore: false));
        return;
      }

      emit(
        cur.copyWith(
          items: [...cur.items, ...newItems],
          hasMore: page.hasMore,
          isLoadingMore: false,
          isRefreshing: false,
        ),
      );
    } catch (_) {
      if (isClosed) return;
      emit(cur.copyWith(isLoadingMore: false, isRefreshing: false));
    }
  }

  Future<void> _fetch({required bool reset}) async {
    try {
      final page = await _repository.listFeed(filter: _filter, limit: _pageSize);
      if (isClosed) return;

      if (reset) {
        _sessionFollowToggledAuthorIds.clear();
        _followUpdatingAuthorIds.clear();
      }

      emit(
        EventsFeedState.loaded(
          filter: _filter,
          items: page.items,
          hasMore: page.hasMore,
          isLoadingMore: false,
          isRefreshing: false,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      final cur = state.mapOrNull(loaded: (s) => s);
      if (cur != null && cur.items.isNotEmpty) {
        emit(cur.copyWith(isRefreshing: false, isLoadingMore: false));
        return;
      }
      emit(EventsFeedState.error(filter: _filter, message: '$e'));
    }
  }
}

@freezed
class EventsFeedState with _$EventsFeedState {
  const factory EventsFeedState.initial() = _Initial;

  const factory EventsFeedState.loading({required EventsFilter filter}) = _Loading;

  const factory EventsFeedState.loaded({
    required EventsFilter filter,
    required List<PostFeedItem> items,
    required bool hasMore,
    @Default(false) bool isLoadingMore,
    @Default(false) bool isRefreshing,
  }) = _Loaded;

  const factory EventsFeedState.error({required EventsFilter filter, required String message}) = _Error;
}
