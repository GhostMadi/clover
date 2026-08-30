import 'package:clover/feature/archive/post_archive/data/repository/post_archive_repository.dart';
import 'package:clover/feature/post/data/models/post_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

@injectable
class PostArchiveCubit extends Cubit<PostArchiveState> {
  PostArchiveCubit(this._repository) : super(const PostArchiveState.initial());

  final PostArchiveRepository _repository;

  Future<void> load(String userId) async {
    if (isClosed) return;
    emit(const PostArchiveState.loading());
    try {
      final items = await _repository.listArchivedPublications(userId);
      if (isClosed) return;
      emit(PostArchiveState.loaded(items));
    } catch (e) {
      if (isClosed) return;
      emit(PostArchiveState.error('$e'));
    }
  }
}

sealed class PostArchiveState {
  const PostArchiveState();

  const factory PostArchiveState.initial() = PostArchiveInitial;
  const factory PostArchiveState.loading() = PostArchiveLoading;
  const factory PostArchiveState.loaded(List<PostModel> posts) = PostArchiveLoaded;
  const factory PostArchiveState.error(String message) = PostArchiveError;
}

final class PostArchiveInitial extends PostArchiveState {
  const PostArchiveInitial();
}

final class PostArchiveLoading extends PostArchiveState {
  const PostArchiveLoading();
}

final class PostArchiveLoaded extends PostArchiveState {
  const PostArchiveLoaded(this.posts);
  final List<PostModel> posts;
}

final class PostArchiveError extends PostArchiveState {
  const PostArchiveError(this.message);
  final String message;
}
