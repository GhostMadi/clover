import 'dart:developer';

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

  Future<void> load(String userId, {String? clusterId, bool onlyWithoutCluster = false}) async {
    if (isClosed) return;
    final id = userId.trim();
    if (id.isEmpty) return;

    _userId = id;
    _clusterId = clusterId?.trim();
    _onlyWithoutCluster = onlyWithoutCluster;

    final cached = await _localCache.readFeed(id);
    log(cached!.map((m) => m.toJson()).toString());
    if (cached.isNotEmpty) {
      emit(
        PostFeedState.loaded(
          posts: cached,
          savedByPostId: const {},
          hasMore: true,
          isLoadingMore: false,
          isFromCache: true,
        ),
      );
    } else {
      emit(const PostFeedState.loading());
    }

    await _fetchRemote(reset: true);
  }

  Future<void> reload() async {
    final id = _userId;
    if (id == null || id.isEmpty) return;
    await load(id, clusterId: _clusterId, onlyWithoutCluster: _onlyWithoutCluster);
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
      );
      if (isClosed) return;

      final merged = [...cur.posts, ...more.map((e) => e.post)];
      final saved = Map<String, bool>.from(cur.savedByPostId);
      for (final e in more) {
        saved[e.post.id] = e.mySaved;
      }

      emit(
        cur.copyWith(
          posts: merged,
          savedByPostId: saved,
          hasMore: more.length == _pageSize,
          isLoadingMore: false,
          isFromCache: false,
          isRefreshing: false,
        ),
      );
      await _localCache.writeFeed(id, merged);
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
      );
      if (isClosed) return;

      final posts = enriched.map((e) => e.post).toList(growable: false);
      final saved = {for (final e in enriched) e.post.id: e.mySaved};

      emit(
        PostFeedState.loaded(
          posts: posts,
          savedByPostId: saved,
          hasMore: posts.length == _pageSize,
          isLoadingMore: false,
          isFromCache: false,
        ),
      );
      await _localCache.writeFeed(id, posts);
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
    required this.hasMore,
    required this.isLoadingMore,
    this.isFromCache = false,
    this.isRefreshing = false,
  });

  final List<PostModel> posts;
  final Map<String, bool> savedByPostId;
  final bool hasMore;
  final bool isLoadingMore;
  final bool isFromCache;
  final bool isRefreshing;

  PostFeedLoaded copyWith({
    List<PostModel>? posts,
    Map<String, bool>? savedByPostId,
    bool? hasMore,
    bool? isLoadingMore,
    bool? isFromCache,
    bool? isRefreshing,
  }) {
    return PostFeedLoaded(
      posts: posts ?? this.posts,
      savedByPostId: savedByPostId ?? this.savedByPostId,
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
