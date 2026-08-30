import 'dart:math';

import 'package:clover/feature/_chat_/chat/data/chat_enriched_mapper.dart';
import 'package:clover/feature/_chat_/chat_page/data/models/chat_message.dart';
import 'package:clover/feature/_chat_/message_page/data/models/message_chat_preview.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class ChatRepository {
  Future<List<MessageChatPreview>> listConversations({int limit = 50, int offset = 0});

  Future<List<ChatMessage>> listMessages(
    String conversationId, {
    int limit = 50,
    DateTime? before,
  });

  Future<ChatMessage?> getMessageEnriched(String messageId);

  Future<String> sendTextMessage({
    required String conversationId,
    required String text,
    String? clientMessageId,
  });

  Future<void> markConversationRead({
    required String conversationId,
    String? lastMessageId,
  });

  Future<String> createDm(String otherUserId);
}

@LazySingleton(as: ChatRepository)
class ChatRepositoryImpl implements ChatRepository {
  ChatRepositoryImpl(this._client);

  final SupabaseClient _client;

  String? get _currentUserId => _client.auth.currentUser?.id.trim();

  @override
  Future<List<MessageChatPreview>> listConversations({int limit = 50, int offset = 0}) async {
    final uid = _currentUserId;
    if (uid == null || uid.isEmpty) return const [];

    final res = await _client.rpc(
      'list_conversations_enriched',
      params: {
        'p_limit': limit,
        'p_offset': offset,
      },
    );

    if (res is! List) return const [];

    final previews = <MessageChatPreview>[];
    for (final raw in res) {
      if (raw is! Map) continue;
      final preview = ChatEnrichedMapper.toConversationPreview(
        Map<String, dynamic>.from(raw),
        currentUserId: uid,
      );
      if (preview != null) previews.add(preview);
    }
    return previews;
  }

  @override
  Future<List<ChatMessage>> listMessages(
    String conversationId, {
    int limit = 50,
    DateTime? before,
  }) async {
    final uid = _currentUserId;
    final id = conversationId.trim();
    if (uid == null || uid.isEmpty || id.isEmpty) return const [];

    final params = <String, dynamic>{
      'p_conversation_id': id,
      'p_limit': limit,
    };
    if (before != null) {
      params['p_before'] = before.toUtc().toIso8601String();
    }

    final res = await _client.rpc('list_messages_enriched', params: params);
    if (res is! List) return const [];

    final messages = <ChatMessage>[];
    for (final raw in res) {
      if (raw is! Map) continue;
      final message = ChatEnrichedMapper.toChatMessage(
        Map<String, dynamic>.from(raw),
        currentUserId: uid,
      );
      if (message != null) messages.add(message);
    }
    return messages;
  }

  @override
  Future<ChatMessage?> getMessageEnriched(String messageId) async {
    final uid = _currentUserId;
    final id = messageId.trim();
    if (uid == null || uid.isEmpty || id.isEmpty) return null;

    final res = await _client.rpc('get_message_enriched', params: {'p_message_id': id});
    if (res is! List || res.isEmpty) return null;

    final raw = res.first;
    if (raw is! Map) return null;

    return ChatEnrichedMapper.toChatMessage(
      Map<String, dynamic>.from(raw),
      currentUserId: uid,
    );
  }

  @override
  Future<String> sendTextMessage({
    required String conversationId,
    required String text,
    String? clientMessageId,
  }) async {
    final id = conversationId.trim();
    final body = text.trim();
    if (id.isEmpty) throw const ChatRepositoryException('Некорректный чат');
    if (body.isEmpty) throw const ChatRepositoryException('Пустое сообщение');

    final params = <String, dynamic>{
      'p_conversation_id': id,
      'p_kind': 'text',
      'p_text': body,
    };
    final clientId = clientMessageId?.trim();
    if (clientId != null && clientId.isNotEmpty) {
      params['p_client_message_id'] = clientId;
    }

    final res = await _client.rpc('send_message', params: params);
    final messageId = res?.toString().trim();
    if (messageId == null || messageId.isEmpty) {
      throw const ChatRepositoryException('Не удалось отправить сообщение');
    }
    return messageId;
  }

  @override
  Future<void> markConversationRead({
    required String conversationId,
    String? lastMessageId,
  }) async {
    final id = conversationId.trim();
    if (id.isEmpty) return;

    final params = <String, dynamic>{'p_conversation_id': id};
    final lastId = lastMessageId?.trim();
    if (lastId != null && lastId.isNotEmpty) {
      params['p_last_message_id'] = lastId;
    }

    await _client.rpc('mark_conversation_read', params: params);
  }

  @override
  Future<String> createDm(String otherUserId) async {
    final id = otherUserId.trim();
    if (id.isEmpty) throw const ChatRepositoryException('Некорректный пользователь');

    final res = await _client.rpc('create_dm', params: {'p_other_user_id': id});
    final conversationId = res?.toString().trim();
    if (conversationId == null || conversationId.isEmpty) {
      throw const ChatRepositoryException('Не удалось открыть чат');
    }
    return conversationId;
  }

  static String newClientMessageId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    String hex(int value) => value.toRadixString(16).padLeft(2, '0');
    final hash = bytes.map(hex).join();
    return '${hash.substring(0, 8)}-${hash.substring(8, 12)}-${hash.substring(12, 16)}-${hash.substring(16, 20)}-${hash.substring(20)}';
  }
}

class ChatRepositoryException implements Exception {
  const ChatRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}
