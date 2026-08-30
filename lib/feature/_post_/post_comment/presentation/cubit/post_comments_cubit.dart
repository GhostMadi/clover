import 'package:clover/feature/_post_/post_comment/data/models/comment_item.dart';
import 'package:clover/feature/_post_/post_comment/data/models/comment_model.dart';
import 'package:clover/feature/_post_/post_comment/data/models/comment_thread_entry.dart';
import 'package:clover/feature/_post_/post_comment/data/models/post_comments_cache_snapshot.dart';
import 'package:clover/feature/_post_/post_comment/data/repository/post_comment_local_cache.dart';
import 'package:clover/feature/_post_/post_comment/data/repository/post_comment_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

@injectable
class PostCommentsCubit extends Cubit<PostCommentsState> {
  PostCommentsCubit(this._repository, this._localCache, this._client) : super(const PostCommentsState.initial());

  final PostCommentRepository _repository;
  final PostCommentLocalCache _localCache;
  final SupabaseClient _client;

  static const _pageSize = 24;

  String? _postId;
  int _commentsCount = 0;
  bool _countDirty = false;

  int get commentsCount => _commentsCount;
  bool get countDirty => _countDirty;

  String? get _currentUserId => _client.auth.currentUser?.id.trim();

  Future<void> load({required String postId, int? initialCommentsCount}) async {
    if (isClosed) return;

    _postId = postId.trim();
    _commentsCount = initialCommentsCount ?? 0;
    _countDirty = false;

    final uid = _currentUserId;
    final cached = uid == null ? null : await _localCache.read(uid, _postId!);
    if (isClosed) return;

    if (cached != null && cached.threads.isNotEmpty) {
      emit(
        PostCommentsState.loaded(
          threads: cached.threads,
          hasMore: cached.hasMore,
          isFromCache: true,
        ),
      );
    } else {
      emit(const PostCommentsState.loading());
    }

    await _fetchRoots(reset: true);
  }

  Future<void> loadMore() async {
    final cur = state;
    if (cur is! PostCommentsLoaded || cur.isLoadingMore || !cur.hasMore || cur.threads.isEmpty) return;

    emit(cur.copyWith(isLoadingMore: true));
    try {
      final more = await _repository.listRootComments(
        postId: _postId!,
        limit: _pageSize,
        offset: cur.threads.length,
      );
      if (isClosed) return;

      final next = cur.copyWith(
        threads: [...cur.threads, ...more.map((e) => CommentThreadEntry(root: e))],
        hasMore: more.length >= _pageSize,
        isLoadingMore: false,
        isFromCache: false,
      );
      emit(next);
      await _persistLoaded(next);
    } catch (_) {
      if (isClosed) return;
      emit(cur.copyWith(isLoadingMore: false));
    }
  }

  Future<void> toggleReplies(String rootCommentId) async {
    final cur = state;
    if (cur is! PostCommentsLoaded) return;

    final index = cur.threads.indexWhere((e) => e.root.comment.id == rootCommentId);
    if (index < 0) return;

    final entry = cur.threads[index];
    if (entry.repliesExpanded) {
      await _replaceThread(cur, index, entry.copyWith(repliesExpanded: false));
      return;
    }

    if (entry.replies.isNotEmpty) {
      await _replaceThread(cur, index, entry.copyWith(repliesExpanded: true));
      return;
    }

    await _replaceThread(cur, index, entry.copyWith(repliesLoading: true, repliesExpanded: true));

    try {
      final replies = await _repository.listReplies(
        postId: _postId!,
        parentCommentId: rootCommentId,
      );
      if (isClosed) return;

      final latest = state;
      if (latest is! PostCommentsLoaded) return;
      final latestIndex = latest.threads.indexWhere((e) => e.root.comment.id == rootCommentId);
      if (latestIndex < 0) return;

      await _replaceThread(
        latest,
        latestIndex,
        latest.threads[latestIndex].copyWith(
          replies: replies,
          repliesLoading: false,
          repliesExpanded: true,
        ),
      );
    } catch (_) {
      if (isClosed) return;
      final latest = state;
      if (latest is! PostCommentsLoaded) return;
      final latestIndex = latest.threads.indexWhere((e) => e.root.comment.id == rootCommentId);
      if (latestIndex < 0) return;
      await _replaceThread(
        latest,
        latestIndex,
        latest.threads[latestIndex].copyWith(repliesLoading: false, repliesExpanded: false),
      );
    }
  }

  void setReplyTarget(CommentModel? comment) {
    final cur = state;
    if (cur is! PostCommentsLoaded) return;
    emit(cur.copyWith(replyTarget: comment));
  }

  Future<void> submitComment(String rawText) async {
    final cur = state;
    if (cur is! PostCommentsLoaded) return;

    final text = rawText.trim();
    if (text.isEmpty) return;

    final postId = _postId;
    if (postId == null || postId.isEmpty) return;

    final replyTarget = cur.replyTarget;
    final parentId = replyTarget?.id;

    final created = await _repository.createComment(
      postId: postId,
      text: text,
      parentCommentId: parentId,
    );
    if (isClosed) return;

    _commentsCount += 1;
    _countDirty = true;

    final latest = state;
    if (latest is! PostCommentsLoaded) return;

    if (parentId == null) {
      final next = latest.copyWith(
        threads: [CommentThreadEntry(root: created), ...latest.threads],
        replyTarget: null,
        clearReplyTarget: true,
        isFromCache: false,
      );
      emit(next);
      await _persistLoaded(next);
      return;
    }

    final rootId = replyTarget!.isRoot ? replyTarget.id : replyTarget.parentCommentId!;
    final rootIndex = latest.threads.indexWhere((e) => e.root.comment.id == rootId);

    if (rootIndex < 0) {
      emit(latest.copyWith(replyTarget: null, clearReplyTarget: true));
      await _fetchRoots(reset: true);
      return;
    }

    final entry = latest.threads[rootIndex];
    final nextReplies = entry.repliesExpanded ? [...entry.replies, created] : entry.replies;
    final nextRoot = entry.root.copyWith(
      comment: entry.root.comment.copyWith(repliesCount: entry.root.comment.repliesCount + 1),
    );

    final next = latest.copyWith(
      threads: [
        for (var i = 0; i < latest.threads.length; i++)
          if (i == rootIndex)
            entry.copyWith(
              root: nextRoot,
              replies: nextReplies,
              repliesExpanded: true,
            )
          else
            latest.threads[i],
      ],
      clearReplyTarget: true,
      isFromCache: false,
    );
    emit(next);
    await _persistLoaded(next);
  }

  Future<void> toggleLike(CommentItem item) async {
    final cur = state;
    if (cur is! PostCommentsLoaded) return;

    final nextKind = item.isLiked ? null : 'like';
    final optimistic = _applyReaction(item, nextKind);
    final optimisticState = cur.copyWith(threads: _patchItemInThreads(cur.threads, optimistic));
    emit(optimisticState);
    await _persistLoaded(optimisticState);

    try {
      final confirmed = await _repository.setReaction(commentId: item.comment.id, kind: nextKind);
      if (isClosed) return;

      final latest = state;
      if (latest is! PostCommentsLoaded) return;

      final reconciled = _applyReaction(optimistic, confirmed);
      final next = latest.copyWith(threads: _patchItemInThreads(latest.threads, reconciled));
      emit(next);
      await _persistLoaded(next);
    } catch (_) {
      if (isClosed) return;
      final latest = state;
      if (latest is! PostCommentsLoaded) return;
      final next = latest.copyWith(threads: _patchItemInThreads(latest.threads, item));
      emit(next);
      await _persistLoaded(next);
    }
  }

  CommentItem _applyReaction(CommentItem item, String? nextKind) {
    final wasLiked = item.isLiked;
    final willLike = nextKind == 'like';
    var likes = item.comment.likesCount;

    if (wasLiked) likes--;
    if (willLike) likes++;

    return item.copyWith(
      myKind: nextKind,
      clearMyKind: nextKind == null,
      comment: item.comment.copyWith(likesCount: likes < 0 ? 0 : likes),
    );
  }

  List<CommentThreadEntry> _patchItemInThreads(List<CommentThreadEntry> threads, CommentItem updated) {
    final id = updated.comment.id;
    return [
      for (final thread in threads)
        if (thread.root.comment.id == id)
          thread.copyWith(root: updated)
        else if (thread.replies.any((r) => r.comment.id == id))
          thread.copyWith(
            replies: [
              for (final reply in thread.replies)
                if (reply.comment.id == id) updated else reply,
            ],
          )
        else
          thread,
    ];
  }

  Future<void> _replaceThread(
    PostCommentsLoaded cur,
    int index,
    CommentThreadEntry entry,
  ) async {
    final next = [...cur.threads];
    next[index] = entry;
    final loaded = cur.copyWith(threads: next, isFromCache: false);
    emit(loaded);
    await _persistLoaded(loaded);
  }

  Future<void> _fetchRoots({required bool reset}) async {
    final postId = _postId;
    if (postId == null || postId.isEmpty) return;

    final previous = state is PostCommentsLoaded ? state as PostCommentsLoaded : null;

    try {
      final roots = await _repository.listRootComments(postId: postId, limit: _pageSize);
      if (isClosed) return;

      final threads = _mergeThreadsWithPrevious(roots, previous?.threads ?? const []);
      final next = PostCommentsLoaded(
        threads: threads,
        hasMore: roots.length >= _pageSize,
        isLoadingMore: false,
        isFromCache: false,
      );
      emit(next);
      await _persistLoaded(next);
    } catch (e) {
      if (isClosed) return;
      if (previous != null && previous.threads.isNotEmpty) {
        emit(previous.copyWith(isFromCache: true));
        return;
      }
      emit(PostCommentsState.error('$e'));
    }
  }

  List<CommentThreadEntry> _mergeThreadsWithPrevious(
    List<CommentItem> roots,
    List<CommentThreadEntry> previous,
  ) {
    final previousById = {for (final thread in previous) thread.root.comment.id: thread};

    return roots
        .map((root) {
          final prev = previousById[root.comment.id];
          if (prev == null) return CommentThreadEntry(root: root);
          return CommentThreadEntry(
            root: root,
            replies: prev.replies,
            repliesExpanded: prev.repliesExpanded,
          );
        })
        .toList(growable: false);
  }

  Future<void> _persistLoaded(PostCommentsLoaded state) async {
    final uid = _currentUserId;
    final postId = _postId;
    if (uid == null || postId == null || postId.isEmpty) return;

    await _localCache.write(
      uid,
      postId,
      PostCommentsCacheSnapshot(
        threads: state.threads,
        hasMore: state.hasMore,
      ),
    );
  }
}

sealed class PostCommentsState {
  const PostCommentsState();

  const factory PostCommentsState.initial() = PostCommentsInitial;
  const factory PostCommentsState.loading() = PostCommentsLoading;
  const factory PostCommentsState.loaded({
    required List<CommentThreadEntry> threads,
    required bool hasMore,
    bool isLoadingMore,
    bool isFromCache,
    CommentModel? replyTarget,
  }) = PostCommentsLoaded;
  const factory PostCommentsState.error(String message) = PostCommentsError;
}

final class PostCommentsInitial extends PostCommentsState {
  const PostCommentsInitial();
}

final class PostCommentsLoading extends PostCommentsState {
  const PostCommentsLoading();
}

final class PostCommentsLoaded extends PostCommentsState {
  const PostCommentsLoaded({
    required this.threads,
    required this.hasMore,
    this.isLoadingMore = false,
    this.isFromCache = false,
    this.replyTarget,
  });

  final List<CommentThreadEntry> threads;
  final bool hasMore;
  final bool isLoadingMore;
  final bool isFromCache;
  final CommentModel? replyTarget;

  PostCommentsLoaded copyWith({
    List<CommentThreadEntry>? threads,
    bool? hasMore,
    bool? isLoadingMore,
    bool? isFromCache,
    CommentModel? replyTarget,
    bool clearReplyTarget = false,
  }) {
    return PostCommentsLoaded(
      threads: threads ?? this.threads,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isFromCache: isFromCache ?? this.isFromCache,
      replyTarget: clearReplyTarget ? null : (replyTarget ?? this.replyTarget),
    );
  }
}

final class PostCommentsError extends PostCommentsState {
  const PostCommentsError(this.message);
  final String message;
}
