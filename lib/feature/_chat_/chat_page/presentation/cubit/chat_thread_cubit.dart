import 'package:clover/feature/chat/data/chat_enriched_mapper.dart';
import 'package:clover/feature/chat/data/repository/chat_local_cache.dart';
import 'package:clover/feature/chat/data/repository/chat_repository.dart';
import 'package:clover/feature/chat_page/data/models/chat_message.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

@injectable
class ChatThreadCubit extends Cubit<ChatThreadState> {
  ChatThreadCubit(this._repository, this._localCache, this._client)
      : super(const ChatThreadState.initial());

  final ChatRepository _repository;
  final ChatLocalCache _localCache;
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

    final uid = _currentUserId;
    if (uid == null || uid.isEmpty) {
      emit(const ChatThreadState.error('Войдите в аккаунт'));
      return;
    }

    _conversationId = id;

    final cached = await _localCache.readMessages(uid, id);
    if (isClosed) return;

    if (cached != null && cached.isNotEmpty) {
      final repairedCache = await _repairPostShareMessages(cached);
      if (isClosed) return;
      emit(ChatThreadState.loaded(messages: repairedCache, isFromCache: true));
      _subscribe(id);
    } else {
      emit(const ChatThreadState.loading());
    }

    await _fetchRemote(resetSubscription: cached == null || cached.isEmpty);
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

    final nextMessages = [...cur.messages, optimistic];
    emit(
      cur.copyWith(
        messages: nextMessages,
        isSending: true,
        clearSendError: true,
      ),
    );
    await _persistMessages(uid, id, nextMessages);

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
      final patched = [
        for (final message in latest.messages)
          if (_sameOptimistic(message, clientMessageId))
            confirmed ?? message.copyWith(id: serverId, isPending: false)
          else
            message,
      ];

      emit(latest.copyWith(messages: patched, isSending: false));
      await _persistMessages(uid, id, patched);
      await _markRead(patched);
    } catch (error) {
      if (isClosed) return;

      final latest = state;
      if (latest is! ChatThreadLoaded) return;

      final rolledBack = [
        for (final message in latest.messages)
          if (!_sameOptimistic(message, clientMessageId)) message,
      ];

      emit(
        latest.copyWith(
          messages: rolledBack,
          isSending: false,
          sendError: _messageFor(error),
        ),
      );
      await _persistMessages(uid, id, rolledBack);
    }
  }

  Future<void> refresh() async {
    final id = _conversationId;
    if (id == null) return;

    final cur = state;
    if (cur is ChatThreadLoaded) {
      emit(cur.copyWith(isRefreshing: true, clearSendError: true));
    }

    await _fetchRemote(resetSubscription: false);
  }

  Future<void> _fetchRemote({required bool resetSubscription}) async {
    final id = _conversationId;
    final uid = _currentUserId;
    if (id == null || uid == null) return;

    try {
      final remote = await _repository.listMessages(id);
      if (isClosed) return;

      final repairedRemote = await _repairPostShareMessages(remote);
      if (isClosed) return;

      final current = state;
      final pending = current is ChatThreadLoaded
          ? current.messages.where((message) => message.isPending).toList(growable: false)
          : const <ChatMessage>[];

      final messages = _mergeWithPending(repairedRemote, pending);
      emit(
        ChatThreadState.loaded(
          messages: messages,
          isFromCache: false,
          isRefreshing: false,
        ),
      );
      await _persistMessages(uid, id, messages);
      await _markRead(messages);

      if (resetSubscription) {
        _subscribe(id);
      }
    } catch (error) {
      if (isClosed) return;

      final cur = state;
      if (cur is ChatThreadLoaded && cur.messages.isNotEmpty) {
        emit(cur.copyWith(isRefreshing: false));
        return;
      }
      emit(ChatThreadState.error(_messageFor(error)));
    }
  }

  Future<List<ChatMessage>> _repairPostShareMessages(List<ChatMessage> messages) async {
    final repaired = <ChatMessage>[];
    for (final message in messages) {
      if (message.isPostShare && !message.hasPostPreview && !message.isPending) {
        final enriched = await _repository.getMessageEnriched(message.id);
        repaired.add(enriched ?? message);
      } else {
        repaired.add(message);
      }
    }
    return repaired;
  }

  List<ChatMessage> _mergeWithPending(List<ChatMessage> remote, List<ChatMessage> pending) {
    if (pending.isEmpty) return remote;

    final remoteClientIds = remote.map((m) => m.clientMessageId).whereType<String>().toSet();
    final remoteIds = remote.map((m) => m.id).toSet();

    final extras = pending.where((message) {
      final clientId = message.clientMessageId ?? message.id;
      return !remoteClientIds.contains(clientId) && !remoteIds.contains(message.id);
    });

    final merged = [...remote, ...extras];
    merged.sort(_compareMessages);
    return merged;
  }

  int _compareMessages(ChatMessage a, ChatMessage b) {
    final byTime = a.sentAt.compareTo(b.sentAt);
    if (byTime != 0) return byTime;
    return a.id.compareTo(b.id);
  }

  Future<void> _persistMessages(String userId, String conversationId, List<ChatMessage> messages) async {
    final persisted = messages.where((message) => !message.isPending).toList(growable: false);
    if (persisted.isEmpty) return;
    await _localCache.writeMessages(userId, conversationId, persisted);
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

  void _onMessageEnriched(Map<String, dynamic> payload) async {
    final uid = _currentUserId;
    final conversationId = _conversationId;
    if (uid == null || conversationId == null) return;

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

    nextMessages.sort(_compareMessages);

    emit(cur.copyWith(messages: nextMessages));
    await _persistMessages(uid, conversationId, nextMessages);

    if (!message.isMine) {
      _markRead(nextMessages);
    }
  }

  void _onPeerRead(Map<String, dynamic> payload) async {
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
    await _persistMessages(uid, conversationId, nextMessages);
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
    bool isFromCache,
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
    this.isFromCache = false,
    this.sendError,
  });

  final List<ChatMessage> messages;
  final bool isSending;
  final bool isRefreshing;
  final bool isFromCache;
  final String? sendError;

  ChatThreadLoaded copyWith({
    List<ChatMessage>? messages,
    bool? isSending,
    bool? isRefreshing,
    bool? isFromCache,
    String? sendError,
    bool clearSendError = false,
  }) {
    return ChatThreadLoaded(
      messages: messages ?? this.messages,
      isSending: isSending ?? this.isSending,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isFromCache: isFromCache ?? this.isFromCache,
      sendError: clearSendError ? null : (sendError ?? this.sendError),
    );
  }
}

final class ChatThreadError extends ChatThreadState {
  const ChatThreadError(this.message);
  final String message;
}
