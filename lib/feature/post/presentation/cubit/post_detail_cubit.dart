import 'package:clover/feature/post/data/models/post_feed_item.dart';
import 'package:clover/feature/post/data/models/post_model.dart';
import 'package:clover/feature/post/data/repository/post_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

/// Экран одного поста: мгновенно из [initialPost] или RPC `get_post_enriched` по id.
@injectable
class PostDetailCubit extends Cubit<PostDetailState> {
  PostDetailCubit(this._repository) : super(const PostDetailState.initial());

  final PostRepository _repository;

  String? _postId;
  PostModel? _initialPost;

  /// [initialPost] — данные от родителя (лента); без лишнего запроса на детали.
  Future<void> load(String postId, {PostModel? initialPost}) async {
    if (isClosed) return;
    final id = postId.trim();
    if (id.isEmpty) {
      emit(const PostDetailState.error('Некорректный id поста'));
      return;
    }

    _postId = id;
    _initialPost = initialPost;

    final seed = initialPost ?? _repository.getCachedPostById(id);
    if (seed != null) {
      _repository.cachePost(seed);
      emit(
        PostDetailState.loaded(
          PostFeedItem(post: seed),
          isFromCache: true,
        ),
      );
    } else {
      emit(const PostDetailState.loading());
    }

    await _fetchRemote();
  }

  Future<void> reload() async {
    final id = _postId;
    if (id == null || id.isEmpty) return;
    await load(id, initialPost: _initialPost);
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

  Future<void> _fetchRemote() async {
    final id = _postId;
    if (id == null) return;

    try {
      final item = await _repository.getPostEnriched(id);
      if (isClosed) return;

      if (item == null) {
        final cur = state;
        if (cur is PostDetailLoaded) {
          emit(cur.copyWith(isRefreshing: false));
          return;
        }
        emit(const PostDetailState.error('Пост недоступен'));
        return;
      }

      emit(
        PostDetailState.loaded(
          item,
          isFromCache: false,
          isRefreshing: false,
        ),
      );
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
}

sealed class PostDetailState {
  const PostDetailState();

  const factory PostDetailState.initial() = PostDetailInitial;
  const factory PostDetailState.loading() = PostDetailLoading;
  const factory PostDetailState.loaded(
    PostFeedItem item, {
    bool isFromCache,
    bool isRefreshing,
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
  });

  final PostFeedItem item;
  final bool isFromCache;
  final bool isRefreshing;

  PostDetailLoaded copyWith({
    PostFeedItem? item,
    bool? isFromCache,
    bool? isRefreshing,
  }) {
    return PostDetailLoaded(
      item ?? this.item,
      isFromCache: isFromCache ?? this.isFromCache,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }
}

final class PostDetailError extends PostDetailState {
  const PostDetailError(this.message);
  final String message;
}
