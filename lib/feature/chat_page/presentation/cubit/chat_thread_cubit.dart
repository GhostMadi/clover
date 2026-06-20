import 'package:clover/feature/chat/data/chat_enriched_mapper.dart';
import 'package:clover/feature/chat/data/repository/chat_repository.dart';
import 'package:clover/feature/chat_page/data/models/chat_message.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

@injectable
class ChatThreadCubit extends Cubit<ChatThreadState> {
  ChatThreadCubit(this._repository, this._client) : super(const ChatThreadState.initial());

  final ChatRepository _repository;
  final SupabaseClient _client;

  RealtimeChannel? _channel;
  String? _conversationId;

  String? get _currentUserId => _client.auth.currentUser?.id.trim();

  Future<void> load(String conversationId) async {
    if (isClosed) return;

    final id = conversationId.trim();
    if (id.isEmpty) {
      emit(const ChatThreadState.error('Некорректный чат'));
      return;
    }

    _conversationId = id;
    emit(const ChatThreadState.loading());

    try {
      final messages = await _repository.listMessages(id);
      if (isClosed) return;

      emit(ChatThreadState.loaded(messages: messages));
      await _markRead(messages);
      _subscribe(id);
    } catch (error) {
      if (isClosed) return;
      emit(ChatThreadState.error(_messageFor(error)));
    }
  }

  Future<void> sendMessage(String text) async {
    final id = _conversationId;
    final uid = _currentUserId;
    if (id == null || uid == null) return;

    final body = text.trim();
    if (body.isEmpty) return;

    final cur = state;
    if (cur is! ChatThreadLoaded) return;

    final clientMessageId = ChatRepositoryImpl.newClientMessageId();
    final optimistic = ChatMessage(
      id: clientMessageId,
      clientMessageId: clientMessageId,
      text: body,
      sentAt: DateTime.now(),
      isMine: true,
      isPending: true,
    );

    emit(
      cur.copyWith(
        messages: [...cur.messages, optimistic],
        isSending: true,
        clearSendError: true,
      ),
    );

    try {
      final serverId = await _repository.sendTextMessage(
        conversationId: id,
        text: body,
        clientMessageId: clientMessageId,
      );

      if (isClosed) return;

      final latest = state;
      if (latest is! ChatThreadLoaded) return;

      final confirmed = await _repository.getMessageEnriched(serverId);
      final nextMessages = [
        for (final message in latest.messages)
          if (_sameOptimistic(message, clientMessageId))
            confirmed ?? message.copyWith(id: serverId, isPending: false)
          else
            message,
      ];

      emit(latest.copyWith(messages: nextMessages, isSending: false));
      await _markRead(nextMessages);
    } catch (error) {
      if (isClosed) return;

      final latest = state;
      if (latest is! ChatThreadLoaded) return;

      emit(
        latest.copyWith(
          messages: [
            for (final message in latest.messages)
              if (!_sameOptimistic(message, clientMessageId)) message,
          ],
          isSending: false,
          sendError: _messageFor(error),
        ),
      );
    }
  }

  Future<void> refresh() async {
    final id = _conversationId;
    if (id == null) return;

    final cur = state;
    if (cur is ChatThreadLoaded) {
      emit(cur.copyWith(isRefreshing: true, clearSendError: true));
    }

    try {
      final messages = await _repository.listMessages(id);
      if (isClosed) return;
      emit(ChatThreadState.loaded(messages: messages));
      await _markRead(messages);
    } catch (error) {
      if (isClosed) return;
      emit(ChatThreadState.error(_messageFor(error)));
    }
  }

  Future<void> _markRead(List<ChatMessage> messages) async {
    final id = _conversationId;
    if (id == null || messages.isEmpty) return;

    final lastId = messages.last.id;
    try {
      await _repository.markConversationRead(
        conversationId: id,
        lastMessageId: lastId,
      );
    } catch (_) {}
  }

  void _subscribe(String conversationId) {
    _channel?.unsubscribe();
    _channel = _client.channel('chat_thread_$conversationId')
      ..onBroadcast(
        event: 'message_enriched',
        callback: (payload) => _onMessageEnriched(payload),
      )
      ..onBroadcast(
        event: 'peer_read',
        callback: (payload) => _onPeerRead(payload),
      )
      ..subscribe();
  }

  void _onMessageEnriched(Map<String, dynamic> payload) {
    final uid = _currentUserId;
    if (uid == null) return;

    final data = payload['payload'] ?? payload;
    if (data is! Map) return;

    final row = Map<String, dynamic>.from(data);
    final message = ChatEnrichedMapper.toChatMessage(row, currentUserId: uid);
    if (message == null) return;

    final cur = state;
    if (cur is! ChatThreadLoaded) return;

    final clientId = message.clientMessageId;
    final existingIndex = cur.messages.indexWhere(
      (item) =>
          item.id == message.id ||
          (clientId != null && item.clientMessageId == clientId) ||
          (clientId != null && item.id == clientId),
    );

    final nextMessages = [...cur.messages];
    if (existingIndex >= 0) {
      nextMessages[existingIndex] = message.copyWith(isPending: false);
    } else {
      nextMessages.add(message);
    }

    nextMessages.sort((a, b) {
      final byTime = a.sentAt.compareTo(b.sentAt);
      if (byTime != 0) return byTime;
      return a.id.compareTo(b.id);
    });

    emit(cur.copyWith(messages: nextMessages));

    if (!message.isMine) {
      _markRead(nextMessages);
    }
  }

  void _onPeerRead(Map<String, dynamic> payload) {
    final uid = _currentUserId;
    final conversationId = _conversationId;
    if (uid == null || conversationId == null) return;

    final data = payload['payload'] ?? payload;
    if (data is! Map) return;

    final peerUserId = data['user_id']?.toString().trim();
    if (peerUserId == null || peerUserId.isEmpty || peerUserId == uid) return;

    if (data['conversation_id']?.toString().trim() != conversationId) return;

    final lastReadMessageId = data['last_read_message_id']?.toString().trim();
    final cur = state;
    if (cur is! ChatThreadLoaded) return;

    if (lastReadMessageId == null || lastReadMessageId.isEmpty) return;

    final readIndex = cur.messages.indexWhere((message) => message.id == lastReadMessageId);
    final nextMessages = [
      for (var i = 0; i < cur.messages.length; i++)
        if (cur.messages[i].isMine && readIndex >= 0 && i <= readIndex)
          cur.messages[i].copyWith(isRead: true)
        else
          cur.messages[i],
    ];

    emit(cur.copyWith(messages: nextMessages));
  }

  bool _sameOptimistic(ChatMessage message, String clientMessageId) {
    return message.clientMessageId == clientMessageId || message.id == clientMessageId;
  }

  String _messageFor(Object error) {
    if (error is ChatRepositoryException) return error.message;
    final raw = error.toString();
    if (raw.contains('not_authenticated')) return 'Войдите в аккаунт';
    if (raw.contains('not_participant')) return 'Нет доступа к этому чату';
    return 'Не удалось выполнить действие';
  }

  @override
  Future<void> close() {
    _channel?.unsubscribe();
    _channel = null;
    return super.close();
  }
}

sealed class ChatThreadState {
  const ChatThreadState();

  const factory ChatThreadState.initial() = ChatThreadInitial;
  const factory ChatThreadState.loading() = ChatThreadLoading;
  const factory ChatThreadState.loaded({
    required List<ChatMessage> messages,
    bool isSending,
    bool isRefreshing,
    String? sendError,
  }) = ChatThreadLoaded;
  const factory ChatThreadState.error(String message) = ChatThreadError;
}

final class ChatThreadInitial extends ChatThreadState {
  const ChatThreadInitial();
}

final class ChatThreadLoading extends ChatThreadState {
  const ChatThreadLoading();
}

final class ChatThreadLoaded extends ChatThreadState {
  const ChatThreadLoaded({
    required this.messages,
    this.isSending = false,
    this.isRefreshing = false,
    this.sendError,
  });

  final List<ChatMessage> messages;
  final bool isSending;
  final bool isRefreshing;
  final String? sendError;

  ChatThreadLoaded copyWith({
    List<ChatMessage>? messages,
    bool? isSending,
    bool? isRefreshing,
    String? sendError,
    bool clearSendError = false,
  }) {
    return ChatThreadLoaded(
      messages: messages ?? this.messages,
      isSending: isSending ?? this.isSending,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      sendError: clearSendError ? null : (sendError ?? this.sendError),
    );
  }
}

final class ChatThreadError extends ChatThreadState {
  const ChatThreadError(this.message);
  final String message;
}
