import 'package:clover/feature/chat/data/repository/chat_repository.dart';
import 'package:clover/feature/message_page/data/models/message_chat_preview.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

@injectable
class MessageListCubit extends Cubit<MessageListState> {
  MessageListCubit(this._repository) : super(const MessageListState.initial());

  final ChatRepository _repository;

  Future<void> load() async {
    if (isClosed) return;

    final current = state;
    if (current is! MessageListLoaded) {
      emit(const MessageListState.loading());
    } else {
      emit(current.copyWith(isRefreshing: true, clearError: true));
    }

    try {
      final chats = await _repository.listConversations();
      if (isClosed) return;
      emit(MessageListState.loaded(chats: chats));
    } catch (error) {
      if (isClosed) return;
      emit(MessageListState.error(_messageFor(error)));
    }
  }

  Future<void> refresh() => load();

  String _messageFor(Object error) {
    if (error is ChatRepositoryException) return error.message;
    final raw = error.toString();
    if (raw.contains('not_authenticated')) return 'Войдите в аккаунт, чтобы видеть сообщения';
    return 'Не удалось загрузить чаты';
  }
}

sealed class MessageListState {
  const MessageListState();

  const factory MessageListState.initial() = MessageListInitial;
  const factory MessageListState.loading() = MessageListLoading;
  const factory MessageListState.loaded({
    required List<MessageChatPreview> chats,
    bool isRefreshing,
  }) = MessageListLoaded;
  const factory MessageListState.error(String message) = MessageListError;
}

final class MessageListInitial extends MessageListState {
  const MessageListInitial();
}

final class MessageListLoading extends MessageListState {
  const MessageListLoading();
}

final class MessageListLoaded extends MessageListState {
  const MessageListLoaded({
    required this.chats,
    this.isRefreshing = false,
  });

  final List<MessageChatPreview> chats;
  final bool isRefreshing;

  MessageListLoaded copyWith({
    List<MessageChatPreview>? chats,
    bool? isRefreshing,
    bool clearError = false,
  }) {
    return MessageListLoaded(
      chats: chats ?? this.chats,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }
}

final class MessageListError extends MessageListState {
  const MessageListError(this.message);
  final String message;
}
