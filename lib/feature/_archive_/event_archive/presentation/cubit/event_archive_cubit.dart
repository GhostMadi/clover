import 'package:clover/feature/_archive_/event_archive/data/repository/event_archive_repository.dart';
import 'package:clover/feature/_post_/post/data/models/post_feed_item.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

@injectable
class EventArchiveCubit extends Cubit<EventArchiveState> {
  EventArchiveCubit(this._repository) : super(const EventArchiveState.initial());

  final EventArchiveRepository _repository;

  Future<void> load(String ownerId) async {
    if (isClosed) return;
    emit(const EventArchiveState.loading());
    try {
      final items = await _repository.listArchivedEvents(ownerId);
      if (isClosed) return;
      emit(EventArchiveState.loaded(items));
    } catch (e) {
      if (isClosed) return;
      emit(EventArchiveState.error('$e'));
    }
  }
}

sealed class EventArchiveState {
  const EventArchiveState();

  const factory EventArchiveState.initial() = EventArchiveInitial;
  const factory EventArchiveState.loading() = EventArchiveLoading;
  const factory EventArchiveState.loaded(List<PostFeedItem> items) = EventArchiveLoaded;
  const factory EventArchiveState.error(String message) = EventArchiveError;
}

final class EventArchiveInitial extends EventArchiveState {
  const EventArchiveInitial();
}

final class EventArchiveLoading extends EventArchiveState {
  const EventArchiveLoading();
}

final class EventArchiveLoaded extends EventArchiveState {
  const EventArchiveLoaded(this.items);
  final List<PostFeedItem> items;
}

final class EventArchiveError extends EventArchiveState {
  const EventArchiveError(this.message);
  final String message;
}
