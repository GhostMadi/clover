import 'dart:async';

import 'package:clover/core/debug/app_log.dart';
import 'package:clover/feature/_chat_/chat/data/repository/chat_local_cache.dart';
import 'package:clover/feature/_chat_/chat/data/repository/chat_repository.dart';
import 'package:clover/feature/_chat_/chat/presentation/cubit/chat_unread_cubit.dart';
import 'package:clover/feature/_chat_/message_page/data/models/message_chat_preview.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

@injectable
class MessageListCubit extends Cubit<MessageListState> {
  MessageListCubit(
    this._repository,
    this._localCache,
    this._client,
    this._unreadCubit,
  ) : super(const MessageListState.initial());

  final ChatRepository _repository;
  final ChatLocalCache _localCache;
  final SupabaseClient _client;
  final ChatUnreadCubit _unreadCubit;

  StreamSubscription<void>? _inboxSub;
  Timer? _inboxDebounce;

  String? get _currentUserId => _client.auth.currentUser?.id.trim();

  Future<void> load() async {
    if (isClosed) return;

    final uid = _currentUserId;
    if (uid == null || uid.isEmpty) {
      emit(const MessageListState.error('Войдите в аккаунт, чтобы видеть сообщения'));
      return;
    }

    _bindInbox();

    final cached = await _localCache.readConversations(uid);
    if (isClosed) return;

    if (cached != null && cached.isNotEmpty) {
      // Кэш сразу — без лоадера; сеть тихо в фоне.
      emit(MessageListState.loaded(chats: cached, isFromCache: true));
    } else if (state is! MessageListLoaded) {
      emit(const MessageListState.loading());
    }

    try {
      final chats = await _repository.listConversations();
      if (isClosed) return;

      await _localCache.writeConversations(uid, chats);
      emit(MessageListState.loaded(chats: chats, isFromCache: false));
      unawaited(_unreadCubit.refresh());
    } catch (error) {
      if (isClosed) return;

      final cur = state;
      if (cur is MessageListLoaded && cur.chats.isNotEmpty) {
        // Оставляем кэш / текущий список — без ошибки поверх.
        return;
      }
      emit(MessageListState.error(_messageFor(error)));
    }
  }

  Future<void> refresh() => load();

  /// Soft refresh after leaving a thread / app resume (keeps current list visible).
  Future<void> softRefresh() async {
    if (isClosed) return;
    final uid = _currentUserId;
    if (uid == null || uid.isEmpty) return;

    try {
      final chats = await _repository.listConversations();
      if (isClosed) return;
      await _localCache.writeConversations(uid, chats);
      emit(MessageListState.loaded(chats: chats, isFromCache: false));
      unawaited(_unreadCubit.refresh());
    } catch (e, st) {
      AppLog.e('Chat list softRefresh failed', tag: 'ChatInbox', error: e, stackTrace: st);
    }
  }

  void _bindInbox() {
    if (_inboxSub != null) return;
    _inboxSub = _unreadCubit.inboxChanged.listen((_) {
      _inboxDebounce?.cancel();
      _inboxDebounce = Timer(const Duration(milliseconds: 300), () {
        unawaited(softRefresh());
      });
    });
  }

  void _unbindInbox() {
    _inboxDebounce?.cancel();
    unawaited(_inboxSub?.cancel());
    _inboxSub = null;
  }

  @override
  Future<void> close() {
    _unbindInbox();
    return super.close();
  }

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
    bool isFromCache,
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
    this.isFromCache = false,
  });

  final List<MessageChatPreview> chats;
  final bool isRefreshing;
  final bool isFromCache;

  MessageListLoaded copyWith({
    List<MessageChatPreview>? chats,
    bool? isRefreshing,
    bool? isFromCache,
  }) {
    return MessageListLoaded(
      chats: chats ?? this.chats,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isFromCache: isFromCache ?? this.isFromCache,
    );
  }
}

final class MessageListError extends MessageListState {
  const MessageListError(this.message);
  final String message;
}
