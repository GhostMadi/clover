import 'package:clover/feature/_post_/post/data/models/post_model.dart';
import 'package:clover/feature/_settings_/settings_saved_post/data/repository/saved_posts_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

@injectable
class SavedPostsCubit extends Cubit<SavedPostsState> {
  SavedPostsCubit(this._repository) : super(const SavedPostsState.initial());

  final SavedPostsRepository _repository;

  static const _pageSize = 24;

  Future<void> load() async {
    if (isClosed) return;
    emit(const SavedPostsState.loading());
    await _fetch(reset: true);
  }

  Future<void> refresh() async {
    if (isClosed) return;
    final cur = state;
    if (cur is SavedPostsLoaded) {
      emit(cur.copyWith(isRefreshing: true));
    }
    await _fetch(reset: true);
  }

  Future<void> loadMore() async {
    final cur = state;
    if (cur is! SavedPostsLoaded || cur.isLoadingMore || !cur.hasMore || cur.posts.isEmpty) return;

    emit(cur.copyWith(isLoadingMore: true));
    try {
      final more = await _repository.listSavedPosts(limit: _pageSize, offset: cur.posts.length);
      if (isClosed) return;

      emit(
        cur.copyWith(
          posts: [...cur.posts, ...more],
          hasMore: more.length >= _pageSize,
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
      final items = await _repository.listSavedPosts(limit: _pageSize, offset: 0);
      if (isClosed) return;

      emit(
        SavedPostsState.loaded(
          posts: items,
          hasMore: items.length >= _pageSize,
          isLoadingMore: false,
          isRefreshing: false,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      final cur = state;
      if (cur is SavedPostsLoaded && cur.posts.isNotEmpty) {
        emit(cur.copyWith(isRefreshing: false, isLoadingMore: false));
        return;
      }
      emit(SavedPostsState.error('$e'));
    }
  }
}

sealed class SavedPostsState {
  const SavedPostsState();

  const factory SavedPostsState.initial() = SavedPostsInitial;
  const factory SavedPostsState.loading() = SavedPostsLoading;
  const factory SavedPostsState.loaded({
    required List<PostModel> posts,
    required bool hasMore,
    bool isLoadingMore,
    bool isRefreshing,
  }) = SavedPostsLoaded;
  const factory SavedPostsState.error(String message) = SavedPostsError;
}

final class SavedPostsInitial extends SavedPostsState {
  const SavedPostsInitial();
}

final class SavedPostsLoading extends SavedPostsState {
  const SavedPostsLoading();
}

final class SavedPostsLoaded extends SavedPostsState {
  const SavedPostsLoaded({
    required this.posts,
    required this.hasMore,
    this.isLoadingMore = false,
    this.isRefreshing = false,
  });

  final List<PostModel> posts;
  final bool hasMore;
  final bool isLoadingMore;
  final bool isRefreshing;

  SavedPostsLoaded copyWith({
    List<PostModel>? posts,
    bool? hasMore,
    bool? isLoadingMore,
    bool? isRefreshing,
  }) {
    return SavedPostsLoaded(
      posts: posts ?? this.posts,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }
}

final class SavedPostsError extends SavedPostsState {
  const SavedPostsError(this.message);
  final String message;
}
