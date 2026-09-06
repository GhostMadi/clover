import 'package:clover/feature/_archive_/event_archive/data/repository/event_archive_repository.dart';
import 'package:clover/feature/_archive_/post_archive/data/repository/post_archive_repository.dart';
import 'package:clover/feature/_post_/post/data/models/post_feed_item.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

@injectable
class PostArchiveCubit extends Cubit<PostArchiveState> {
  PostArchiveCubit(this._publications, this._events) : super(const PostArchiveState.initial());

  final PostArchiveRepository _publications;
  final EventArchiveRepository _events;

  Future<void> load(String userId) async {
    if (isClosed) return;
    emit(const PostArchiveState.loading());
    try {
      final posts = await _publications.listArchivedPublications(userId);
      final eventItems = await _events.listArchivedEvents(userId);
      if (isClosed) return;

      final byId = <String, PostFeedItem>{};
      for (final post in posts) {
        byId[post.id] = PostFeedItem(post: post);
      }
      // Ивенты перекрывают: нужен marker для разархива карты.
      for (final item in eventItems) {
        byId[item.post.id] = item;
      }

      final items = byId.values.toList(growable: false)
        ..sort((a, b) => b.post.createdAt.compareTo(a.post.createdAt));

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
  const factory PostArchiveState.loaded(List<PostFeedItem> items) = PostArchiveLoaded;
  const factory PostArchiveState.error(String message) = PostArchiveError;
}

final class PostArchiveInitial extends PostArchiveState {
  const PostArchiveInitial();
}

final class PostArchiveLoading extends PostArchiveState {
  const PostArchiveLoading();
}

final class PostArchiveLoaded extends PostArchiveState {
  const PostArchiveLoaded(this.items);
  final List<PostFeedItem> items;
}

final class PostArchiveError extends PostArchiveState {
  const PostArchiveError(this.message);
  final String message;
}
