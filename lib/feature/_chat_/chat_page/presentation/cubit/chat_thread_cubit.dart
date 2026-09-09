import 'dart:async';

import 'package:clover/feature/_chat_/chat/data/chat_enriched_mapper.dart';
import 'package:clover/feature/_chat_/chat/data/models/chat_attachment_upload.dart';
import 'package:clover/feature/_chat_/chat/data/repository/chat_local_cache.dart';
import 'package:clover/feature/_chat_/chat/data/repository/chat_repository.dart';
import 'package:clover/feature/_chat_/chat_page/data/models/chat_message.dart';
import 'package:clover/feature/_chat_/chat_page/data/models/chat_message_reply_preview.dart';
import 'package:clover/feature/_chat_/chat_page/data/models/chat_search_hit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

@injectable
class ChatThreadCubit extends Cubit<ChatThreadState> {
  ChatThreadCubit(this._repository, this._localCache, this._client) : super(const ChatThreadState.initial());

  final ChatRepository _repository;
  final ChatLocalCache _localCache;
  final SupabaseClient _client;

  RealtimeChannel? _channel;
  String? _conversationId;
  DateTime? _lastTypingSent;
  Timer? _peerTypingTimer;

  static const _pageSize = 50;

  String? get _currentUserId => _client.auth.currentUser?.id.trim();

  /// Открыть DM с профиля: сразу показываем пустой чат, create_dm — в фоне.
  Future<void> openWithOtherUser(String otherUserId) async {
    if (isClosed) return;

    final peerId = otherUserId.trim();
    if (peerId.isEmpty) {
      emit(const ChatThreadState.error('Некорректный пользователь'));
      return;
    }

    final uid = _currentUserId;
    if (uid == null || uid.isEmpty) {
      emit(const ChatThreadState.error('Войдите в аккаунт'));
      return;
    }

    emit(const ChatThreadState.loaded(messages: [], isOpeningConversation: true));

    try {
      final conversationId = await _repository.createDm(peerId);
      if (isClosed) return;

      _conversationId = conversationId;

      final cached = await _readCachedMessages(uid, conversationId);
      if (isClosed) return;

      if (cached != null && cached.isNotEmpty) {
        // Cache first — без сетевого repair, синк ниже.
        emit(
          ChatThreadState.loaded(
            messages: cached,
            isFromCache: true,
            isRefreshing: true,
          ),
        );
        _subscribe(conversationId);
      } else {
        emit(const ChatThreadState.loaded(messages: [], isRefreshing: true));
      }

      await _fetchRemote(resetSubscription: cached == null || cached.isEmpty);
    } catch (error) {
      if (isClosed) return;
      emit(ChatThreadState.error(_messageFor(error)));
    }
  }

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

    final cached = await _readCachedMessages(uid, id);
    if (isClosed) return;

    if (cached != null && cached.isNotEmpty) {
      // Сразу кэш на экран, бэк — в фоне.
      emit(
        ChatThreadState.loaded(
          messages: cached,
          isFromCache: true,
          isRefreshing: true,
        ),
      );
      _subscribe(id);
    } else {
      emit(const ChatThreadState.loaded(messages: [], isRefreshing: true));
    }

    await _fetchRemote(resetSubscription: cached == null || cached.isEmpty);
  }

  Future<void> sendAttachments(List<ChatAttachmentUpload> files, {String? caption}) async {
    final id = _conversationId;
    final uid = _currentUserId;
    if (id == null || uid == null || files.isEmpty) return;

    final cur = state;
    if (cur is! ChatThreadLoaded) return;

    final allImages = files.every((file) => file.mime.startsWith('image/'));
    final kind = allImages ? 'media' : 'file';
    final clientMessageId = ChatRepositoryImpl.newClientMessageId();
    final trimmedCaption = caption?.trim();
    final optimistic = ChatMessage(
      id: clientMessageId,
      clientMessageId: clientMessageId,
      text: trimmedCaption?.isNotEmpty == true ? trimmedCaption! : '',
      sentAt: DateTime.now(),
      isMine: true,
      isPending: true,
      kind: kind,
    );

    final nextMessages = [...cur.messages, optimistic];
    emit(
      cur.copyWith(
        messages: nextMessages,
        isSending: true,
        clearSendError: true,
        clearPendingAttachments: true,
      ),
    );

    try {
      final serverId = await _repository.sendAttachments(
        conversationId: id,
        files: files,
        caption: trimmedCaption,
        clientMessageId: clientMessageId,
      );

      if (isClosed) return;

      final latest = state;
      if (latest is! ChatThreadLoaded) return;

      final confirmed = await _repository.getMessageEnriched(serverId);
      final confirmedMessage =
          (confirmed ??
                  ChatMessage(
                    id: serverId,
                    clientMessageId: clientMessageId,
                    text: trimmedCaption?.isNotEmpty == true ? trimmedCaption! : '',
                    sentAt: DateTime.now(),
                    isMine: true,
                    kind: kind,
                  ))
              .copyWith(isPending: false, clientMessageId: clientMessageId);

      final patched = <ChatMessage>[];
      var inserted = false;
      for (final message in latest.messages) {
        final isOptimistic = _sameOptimistic(message, clientMessageId);
        final isServerDup = message.id == serverId;
        if (isOptimistic || isServerDup) {
          if (!inserted) {
            patched.add(confirmedMessage);
            inserted = true;
          }
          continue;
        }
        patched.add(message);
      }
      if (!inserted) patched.add(confirmedMessage);

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

      emit(latest.copyWith(messages: rolledBack, isSending: false, sendError: _messageFor(error)));
    }
  }

  Future<void> toggleReaction(String messageId, String emoji) async {
    final id = messageId.trim();
    final em = emoji.trim();
    if (id.isEmpty || em.isEmpty) return;

    final cur = state;
    if (cur is! ChatThreadLoaded) return;

    try {
      final result = await _repository.toggleMessageReaction(messageId: id, emoji: em);
      if (isClosed) return;

      final latest = state;
      if (latest is! ChatThreadLoaded) return;

      final nextMessages = [
        for (final message in latest.messages)
          if (message.id == id)
            message.copyWith(reactions: result.reactions, myReactions: result.myReactions)
          else
            message,
      ];

      emit(latest.copyWith(messages: nextMessages));

      final conversationId = _conversationId;
      final uid = _currentUserId;
      if (conversationId != null && uid != null) {
        await _persistMessages(uid, conversationId, nextMessages);
      }
    } catch (error) {
      if (isClosed) return;
      final latest = state;
      if (latest is ChatThreadLoaded) {
        emit(latest.copyWith(sendError: _messageFor(error)));
      }
    }
  }

  Future<List<ChatSearchHit>> searchMessages(String query) async {
    final id = _conversationId;
    if (id == null) return const [];

    try {
      return await _repository.searchMessages(query: query, conversationId: id);
    } catch (_) {
      return const [];
    }
  }

  void setReplyTo(ChatMessage? message) {
    final cur = state;
    if (cur is! ChatThreadLoaded) return;
    emit(cur.copyWith(replyToMessage: message, clearEditingMessage: true));
  }

  void setEditingMessage(ChatMessage? message) {
    final cur = state;
    if (cur is! ChatThreadLoaded) return;
    emit(cur.copyWith(editingMessage: message, clearReplyTo: true));
  }

  void clearComposerContext() {
    final cur = state;
    if (cur is! ChatThreadLoaded) return;
    emit(cur.copyWith(clearReplyTo: true, clearEditingMessage: true));
  }

  void addPendingAttachments(List<ChatAttachmentUpload> files) {
    if (files.isEmpty) return;
    final cur = state;
    if (cur is! ChatThreadLoaded) return;
    emit(cur.copyWith(pendingAttachments: [...cur.pendingAttachments, ...files], clearSendError: true));
  }

  void removePendingAttachmentAt(int index) {
    final cur = state;
    if (cur is! ChatThreadLoaded) return;
    if (index < 0 || index >= cur.pendingAttachments.length) return;
    final next = [...cur.pendingAttachments]..removeAt(index);
    emit(cur.copyWith(pendingAttachments: next));
  }

  void clearPendingAttachments() {
    final cur = state;
    if (cur is! ChatThreadLoaded) return;
    if (cur.pendingAttachments.isEmpty) return;
    emit(cur.copyWith(clearPendingAttachments: true));
  }

  Future<void> loadOlderMessages() async {
    final id = _conversationId;
    final cur = state;
    if (id == null || cur is! ChatThreadLoaded || cur.isLoadingOlder || !cur.hasMoreOlder) return;
    if (cur.messages.isEmpty) return;

    emit(cur.copyWith(isLoadingOlder: true));

    try {
      final oldest = cur.messages.first;
      final older = await _repository.listMessages(id, before: oldest.sentAt, limit: _pageSize);
      if (isClosed) return;

      final latest = state;
      if (latest is! ChatThreadLoaded) return;

      final existingIds = latest.messages.map((message) => message.id).toSet();
      final prepend = older.where((message) => !existingIds.contains(message.id)).toList(growable: false);
      final merged = [...prepend, ...latest.messages]..sort(_compareMessages);

      emit(latest.copyWith(messages: merged, isLoadingOlder: false, hasMoreOlder: older.length >= _pageSize));
    } catch (_) {
      if (isClosed) return;
      final latest = state;
      if (latest is ChatThreadLoaded) {
        emit(latest.copyWith(isLoadingOlder: false));
      }
    }
  }

  Future<void> deleteMessage(String messageId) async {
    final id = messageId.trim();
    if (id.isEmpty) return;

    final cur = state;
    if (cur is! ChatThreadLoaded) return;

    try {
      await _repository.deleteMessage(id);
      if (isClosed) return;

      final latest = state;
      if (latest is! ChatThreadLoaded) return;

      final nextMessages = latest.messages.where((message) => message.id != id).toList(growable: false);
      emit(latest.copyWith(messages: nextMessages, clearEditingMessage: latest.editingMessage?.id == id));

      final conversationId = _conversationId;
      final uid = _currentUserId;
      if (conversationId != null && uid != null) {
        await _persistMessages(uid, conversationId, nextMessages);
      }
    } catch (error) {
      if (isClosed) return;
      final latest = state;
      if (latest is ChatThreadLoaded) {
        emit(latest.copyWith(sendError: _messageFor(error)));
      }
    }
  }

  Future<void> forwardMessage(String targetConversationId, ChatMessage message) async {
    try {
      await _repository.forwardMessage(targetConversationId: targetConversationId, message: message);
    } catch (error) {
      if (isClosed) return;
      final cur = state;
      if (cur is ChatThreadLoaded) {
        emit(cur.copyWith(sendError: _messageFor(error)));
      }
      rethrow;
    }
  }

  void notifyTyping() {
    final uid = _currentUserId;
    final conversationId = _conversationId;
    final channel = _channel;
    if (uid == null || conversationId == null || channel == null) return;

    final now = DateTime.now();
    if (_lastTypingSent != null && now.difference(_lastTypingSent!) < const Duration(seconds: 2)) {
      return;
    }
    _lastTypingSent = now;

    unawaited(
      channel.sendBroadcastMessage(
        event: 'typing',
        payload: {'user_id': uid, 'conversation_id': conversationId},
      ),
    );
  }

  Future<void> sendMessage(String text) async {
    final id = _conversationId;
    final uid = _currentUserId;
    if (id == null || uid == null) return;

    final body = text.trim();
    if (body.isEmpty) return;

    final cur = state;
    if (cur is! ChatThreadLoaded) return;

    if (cur.editingMessage != null) {
      await _saveEdit(body, cur);
      return;
    }

    final replyTo = cur.replyToMessage;
    final clientMessageId = ChatRepositoryImpl.newClientMessageId();
    final optimistic = ChatMessage(
      id: clientMessageId,
      clientMessageId: clientMessageId,
      text: body,
      sentAt: DateTime.now(),
      isMine: true,
      isPending: true,
      replyPreview: replyTo == null
          ? null
          : ChatMessageReplyPreview(
              id: replyTo.id,
              text: replyTo.text,
              kind: replyTo.kind,
              senderId: replyTo.isMine ? uid : null,
            ),
    );

    final nextMessages = [...cur.messages, optimistic];
    emit(cur.copyWith(messages: nextMessages, isSending: true, clearSendError: true, clearReplyTo: true));
    await _persistMessages(uid, id, nextMessages);

    try {
      final serverId = await _repository.sendTextMessage(
        conversationId: id,
        text: body,
        clientMessageId: clientMessageId,
        replyToMessageId: replyTo?.id,
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

      emit(latest.copyWith(messages: rolledBack, isSending: false, sendError: _messageFor(error)));
      await _persistMessages(uid, id, rolledBack);
    }
  }

  Future<void> _saveEdit(String body, ChatThreadLoaded cur) async {
    final editing = cur.editingMessage;
    final id = _conversationId;
    final uid = _currentUserId;
    if (editing == null || id == null || uid == null) return;

    emit(cur.copyWith(isSending: true, clearSendError: true));

    try {
      await _repository.editMessage(messageId: editing.id, text: body);
      if (isClosed) return;

      final updated = await _repository.getMessageEnriched(editing.id);
      final latest = state;
      if (latest is! ChatThreadLoaded) return;

      final nextMessages = [
        for (final message in latest.messages)
          if (message.id == editing.id)
            updated ?? message.copyWith(text: body, editedAt: DateTime.now())
          else
            message,
      ];

      emit(latest.copyWith(messages: nextMessages, isSending: false, clearEditingMessage: true));
      await _persistMessages(uid, id, nextMessages);
    } catch (error) {
      if (isClosed) return;
      final latest = state;
      if (latest is! ChatThreadLoaded) return;
      emit(latest.copyWith(isSending: false, sendError: _messageFor(error)));
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

      // Repair только дыр в payload (параллельно), не блокирует показ кэша.
      final repairedRemote = await _repairStructuredMessages(remote);
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
          hasMoreOlder: remote.length >= _pageSize,
          replyToMessage: current is ChatThreadLoaded ? current.replyToMessage : null,
          editingMessage: current is ChatThreadLoaded ? current.editingMessage : null,
          peerIsTyping: current is ChatThreadLoaded ? current.peerIsTyping : false,
          pendingAttachments: current is ChatThreadLoaded ? current.pendingAttachments : const [],
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

  Future<List<ChatMessage>?> _readCachedMessages(String userId, String conversationId) async {
    try {
      return await _localCache.readMessages(userId, conversationId);
    } catch (_) {
      return null;
    }
  }

  Future<List<ChatMessage>> _repairStructuredMessages(List<ChatMessage> messages) async {
    final needRepair = <int>[];
    for (var i = 0; i < messages.length; i++) {
      if (messages[i].needsStructuredCardRepair) needRepair.add(i);
    }
    if (needRepair.isEmpty) return messages;

    final repaired = List<ChatMessage>.from(messages);
    await Future.wait(
      needRepair.map((index) async {
        final message = messages[index];
        final enriched = await _repository.getMessageEnriched(message.id);
        if (enriched != null) repaired[index] = enriched;
      }),
    );
    return repaired;
  }

  List<ChatMessage> _mergeWithPending(List<ChatMessage> remote, List<ChatMessage> pending) {
    if (pending.isEmpty) return remote;

    final remoteClientIds = remote
        .map((m) => m.clientMessageId)
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toSet();
    final remoteIds = remote.map((m) => m.id).toSet();

    final extras = pending.where((message) {
      final clientId = message.clientMessageId ?? message.id;
      if (remoteClientIds.contains(clientId) || remoteIds.contains(message.id)) {
        return false;
      }
      // Drop pending media/file if remote already has a recent own message of same kind.
      if (message.isMedia || message.isFile) {
        final matchedRemote = remote.any(
          (remoteMessage) =>
              remoteMessage.isMine &&
              remoteMessage.kind == message.kind &&
              remoteMessage.sentAt.difference(message.sentAt).abs() <= const Duration(seconds: 30),
        );
        if (matchedRemote) return false;
      }
      return true;
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
      await _repository.markConversationRead(conversationId: id, lastMessageId: lastId);
    } catch (_) {}
  }

  void _subscribe(String conversationId) {
    _channel?.unsubscribe();
    _channel = _client.channel('chat_thread_$conversationId')
      ..onBroadcast(event: 'message_enriched', callback: (payload) => _onMessageEnriched(payload))
      ..onBroadcast(event: 'peer_read', callback: (payload) => _onPeerRead(payload))
      ..onBroadcast(event: 'typing', callback: (payload) => _onTyping(payload))
      ..subscribe();
  }

  void _onTyping(Map<String, dynamic> payload) {
    final uid = _currentUserId;
    final conversationId = _conversationId;
    if (uid == null || conversationId == null) return;

    final data = payload['payload'] ?? payload;
    if (data is! Map) return;

    final peerUserId = data['user_id']?.toString().trim();
    if (peerUserId == null || peerUserId.isEmpty || peerUserId == uid) return;
    if (data['conversation_id']?.toString().trim() != conversationId) return;

    final cur = state;
    if (cur is! ChatThreadLoaded) return;

    emit(cur.copyWith(peerIsTyping: true));
    _peerTypingTimer?.cancel();
    _peerTypingTimer = Timer(const Duration(seconds: 3), () {
      if (isClosed) return;
      final latest = state;
      if (latest is ChatThreadLoaded) {
        emit(latest.copyWith(peerIsTyping: false));
      }
    });
  }

  void _onMessageEnriched(Map<String, dynamic> payload) async {
    final uid = _currentUserId;
    final conversationId = _conversationId;
    if (uid == null || conversationId == null) return;

    final data = payload['payload'] ?? payload;
    if (data is! Map) return;

    final row = Map<String, dynamic>.from(data);
    final message = ChatEnrichedMapper.toChatMessage(row, currentUserId: uid, storageClient: _client);
    if (message == null) return;

    final cur = state;
    if (cur is! ChatThreadLoaded) return;

    final clientId = message.clientMessageId;
    var existingIndex = cur.messages.indexWhere(
      (item) =>
          item.id == message.id ||
          (clientId != null &&
              clientId.isNotEmpty &&
              (item.clientMessageId == clientId || item.id == clientId)),
    );

    // Fallback until client_message_id is on attachment RPC: replace own pending media/file.
    if (existingIndex < 0 && message.isMine && (message.isMedia || message.isFile)) {
      existingIndex = cur.messages.lastIndexWhere(
        (item) => item.isPending && item.isMine && item.kind == message.kind,
      );
    }

    final nextMessages = [...cur.messages];
    if (existingIndex >= 0) {
      nextMessages[existingIndex] = message.copyWith(
        isPending: false,
        clientMessageId: message.clientMessageId ?? cur.messages[existingIndex].clientMessageId,
      );
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
    _peerTypingTimer?.cancel();
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
    bool isOpeningConversation,
    String? sendError,
    ChatMessage? replyToMessage,
    ChatMessage? editingMessage,
    bool isLoadingOlder,
    bool hasMoreOlder,
    bool peerIsTyping,
    List<ChatAttachmentUpload> pendingAttachments,
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
    this.isOpeningConversation = false,
    this.sendError,
    this.replyToMessage,
    this.editingMessage,
    this.isLoadingOlder = false,
    this.hasMoreOlder = true,
    this.peerIsTyping = false,
    this.pendingAttachments = const [],
  });

  final List<ChatMessage> messages;
  final bool isSending;
  final bool isRefreshing;
  final bool isFromCache;
  final bool isOpeningConversation;
  final String? sendError;
  final ChatMessage? replyToMessage;
  final ChatMessage? editingMessage;
  final bool isLoadingOlder;
  final bool hasMoreOlder;
  final bool peerIsTyping;
  final List<ChatAttachmentUpload> pendingAttachments;

  ChatThreadLoaded copyWith({
    List<ChatMessage>? messages,
    bool? isSending,
    bool? isRefreshing,
    bool? isFromCache,
    bool? isOpeningConversation,
    String? sendError,
    ChatMessage? replyToMessage,
    ChatMessage? editingMessage,
    bool? isLoadingOlder,
    bool? hasMoreOlder,
    bool? peerIsTyping,
    List<ChatAttachmentUpload>? pendingAttachments,
    bool clearSendError = false,
    bool clearReplyTo = false,
    bool clearEditingMessage = false,
    bool clearPendingAttachments = false,
  }) {
    return ChatThreadLoaded(
      messages: messages ?? this.messages,
      isSending: isSending ?? this.isSending,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isFromCache: isFromCache ?? this.isFromCache,
      isOpeningConversation: isOpeningConversation ?? this.isOpeningConversation,
      sendError: clearSendError ? null : (sendError ?? this.sendError),
      replyToMessage: clearReplyTo ? null : (replyToMessage ?? this.replyToMessage),
      editingMessage: clearEditingMessage ? null : (editingMessage ?? this.editingMessage),
      isLoadingOlder: isLoadingOlder ?? this.isLoadingOlder,
      hasMoreOlder: hasMoreOlder ?? this.hasMoreOlder,
      peerIsTyping: peerIsTyping ?? this.peerIsTyping,
      pendingAttachments: clearPendingAttachments
          ? const []
          : (pendingAttachments ?? this.pendingAttachments),
    );
  }
}

final class ChatThreadError extends ChatThreadState {
  const ChatThreadError(this.message);
  final String message;
}
