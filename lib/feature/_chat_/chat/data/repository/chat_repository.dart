import 'dart:math';

import 'package:clover/core/network/supabase_edge_functions_invoker.dart';
import 'package:clover/feature/_chat_/chat/data/chat_enriched_mapper.dart';
import 'package:clover/feature/_chat_/chat/data/models/chat_attachment_upload.dart';
import 'package:clover/feature/_chat_/chat_page/data/models/chat_message.dart';
import 'package:clover/feature/_chat_/chat_page/data/models/chat_message_reaction.dart';
import 'package:clover/feature/_chat_/chat_page/data/models/chat_search_hit.dart';
import 'package:clover/feature/_chat_/message_page/data/models/message_chat_preview.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
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
    String? replyToMessageId,
    String? forwardFromMessageId,
    String? postId,
    String kind = 'text',
  });

  Future<void> deleteMessage(String messageId);

  Future<void> editMessage({required String messageId, required String text});

  Future<String> forwardMessage({
    required String targetConversationId,
    required ChatMessage message,
  });

  Future<String> sendAttachments({
    required String conversationId,
    required List<ChatAttachmentUpload> files,
    String? caption,
    String? clientMessageId,
  });

  Future<void> markConversationRead({
    required String conversationId,
    String? lastMessageId,
  });

  Future<String> createDm(String otherUserId);

  Future<String> createGroup({
    required String title,
    required List<String> userIds,
  });

  Future<List<ChatSearchHit>> searchMessages({
    required String query,
    String? conversationId,
    int limit = 50,
  });

  Future<({List<ChatMessageReaction> reactions, List<String> myReactions})> toggleMessageReaction({
    required String messageId,
    required String emoji,
  });
}

@LazySingleton(as: ChatRepository)
class ChatRepositoryImpl implements ChatRepository {
  ChatRepositoryImpl(this._client, this._edgeFunctions);

  final SupabaseClient _client;
  final SupabaseEdgeFunctionsInvoker _edgeFunctions;

  final Map<String, String> _dmConversationByUserId = {};

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
        storageClient: _client,
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
      storageClient: _client,
    );
  }

  @override
  Future<String> sendTextMessage({
    required String conversationId,
    required String text,
    String? clientMessageId,
    String? replyToMessageId,
    String? forwardFromMessageId,
    String? postId,
    String kind = 'text',
  }) async {
    final id = conversationId.trim();
    final body = text.trim();
    final messageKind = kind.trim().isEmpty ? 'text' : kind.trim();
    if (id.isEmpty) throw const ChatRepositoryException('Некорректный чат');
    if (messageKind == 'text' && body.isEmpty) {
      throw const ChatRepositoryException('Пустое сообщение');
    }

    final params = <String, dynamic>{
      'p_conversation_id': id,
      'p_kind': messageKind,
      'p_text': body.isEmpty ? null : body,
    };
    final clientId = clientMessageId?.trim();
    if (clientId != null && clientId.isNotEmpty) {
      params['p_client_message_id'] = clientId;
    }
    final replyTo = replyToMessageId?.trim();
    if (replyTo != null && replyTo.isNotEmpty) {
      params['p_reply_to'] = replyTo;
    }
    final forwardFrom = forwardFromMessageId?.trim();
    if (forwardFrom != null && forwardFrom.isNotEmpty) {
      params['p_forward_from'] = forwardFrom;
    }
    final post = postId?.trim();
    if (post != null && post.isNotEmpty) {
      params['p_post_id'] = post;
    }

    final res = await _client.rpc('send_message', params: params);
    final messageId = res?.toString().trim();
    if (messageId == null || messageId.isEmpty) {
      throw const ChatRepositoryException('Не удалось отправить сообщение');
    }
    return messageId;
  }

  @override
  Future<void> deleteMessage(String messageId) async {
    final id = messageId.trim();
    if (id.isEmpty) throw const ChatRepositoryException('Некорректное сообщение');
    await _client.rpc('delete_message', params: {'p_message_id': id});
  }

  @override
  Future<void> editMessage({required String messageId, required String text}) async {
    final id = messageId.trim();
    final body = text.trim();
    if (id.isEmpty) throw const ChatRepositoryException('Некорректное сообщение');
    if (body.isEmpty) throw const ChatRepositoryException('Пустое сообщение');
    await _client.rpc('edit_message', params: {'p_message_id': id, 'p_text': body});
  }

  @override
  Future<String> forwardMessage({
    required String targetConversationId,
    required ChatMessage message,
  }) async {
    if (message.isPostShare && message.hasPostPreview) {
      return sendTextMessage(
        conversationId: targetConversationId,
        text: message.text,
        kind: 'post_ref',
        postId: message.postRef!.postId,
        forwardFromMessageId: message.id,
      );
    }

    final body = message.text.trim();
    if (body.isEmpty && !message.isMedia && !message.isFile) {
      throw const ChatRepositoryException('Нечего переслать');
    }

    return sendTextMessage(
      conversationId: targetConversationId,
      text: body.isNotEmpty ? body : ChatEnrichedMapper.displayText({'kind': message.kind}, attachmentCount: message.attachments.length),
      forwardFromMessageId: message.id,
      kind: message.kind,
    );
  }

  @override
  Future<String> sendAttachments({
    required String conversationId,
    required List<ChatAttachmentUpload> files,
    String? caption,
    String? clientMessageId,
  }) async {
    final id = conversationId.trim();
    if (id.isEmpty) throw const ChatRepositoryException('Некорректный чат');
    if (files.isEmpty) throw const ChatRepositoryException('Нет файлов для отправки');

    final multipartFiles = <http.MultipartFile>[];
    for (final file in files) {
      if (file.bytes.isEmpty) continue;
      multipartFiles.add(
        http.MultipartFile.fromBytes(
          'files',
          file.bytes,
          filename: file.filename,
          contentType: MediaType.parse(file.mime),
        ),
      );
    }
    if (multipartFiles.isEmpty) {
      throw const ChatRepositoryException('Не удалось прочитать файлы');
    }

    final body = <String, dynamic>{'conversation_id': id};
    final trimmedCaption = caption?.trim();
    if (trimmedCaption != null && trimmedCaption.isNotEmpty) {
      body['caption'] = trimmedCaption;
    }
    final clientId = clientMessageId?.trim();
    if (clientId != null && clientId.isNotEmpty) {
      body['client_message_id'] = clientId;
    }

    final response = await _edgeFunctions.invoke(
      'send_chat_attachments',
      body: body,
      files: multipartFiles,
    );

    final data = response.data;
    if (data is Map) {
      final messageId = data['message_id']?.toString().trim();
      if (messageId != null && messageId.isNotEmpty) return messageId;
    }

    throw const ChatRepositoryException('Не удалось отправить вложение');
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

    final cached = _dmConversationByUserId[id];
    if (cached != null && cached.isNotEmpty) return cached;

    final res = await _client.rpc('create_dm', params: {'p_other_user_id': id});
    final conversationId = res?.toString().trim();
    if (conversationId == null || conversationId.isEmpty) {
      throw const ChatRepositoryException('Не удалось открыть чат');
    }
    _dmConversationByUserId[id] = conversationId;
    return conversationId;
  }

  @override
  Future<String> createGroup({
    required String title,
    required List<String> userIds,
  }) async {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      throw const ChatRepositoryException('Укажите название группы');
    }

    final ids = userIds.map((id) => id.trim()).where((id) => id.isNotEmpty).toList(growable: false);
    if (ids.isEmpty) {
      throw const ChatRepositoryException('Выберите хотя бы одного участника');
    }

    final res = await _client.rpc(
      'create_group',
      params: {
        'p_title': trimmedTitle,
        'p_user_ids': ids,
      },
    );

    final conversationId = res?.toString().trim();
    if (conversationId == null || conversationId.isEmpty) {
      throw const ChatRepositoryException('Не удалось создать группу');
    }
    return conversationId;
  }

  @override
  Future<List<ChatSearchHit>> searchMessages({
    required String query,
    String? conversationId,
    int limit = 50,
  }) async {
    final uid = _currentUserId;
    final q = query.trim();
    if (uid == null || uid.isEmpty || q.isEmpty) return const [];

    final params = <String, dynamic>{
      'p_query': q,
      'p_limit': limit.clamp(1, 200),
    };
    final convId = conversationId?.trim();
    if (convId != null && convId.isNotEmpty) {
      params['p_conversation_id'] = convId;
    }

    final res = await _client.rpc('search_messages', params: params);
    if (res is! List) return const [];

    final hits = <ChatSearchHit>[];
    for (final raw in res) {
      if (raw is! Map) continue;
      final map = Map<String, dynamic>.from(raw);
      final message = map['message'];
      if (message is! Map) continue;

      final messageMap = Map<String, dynamic>.from(message);
      final messageId = messageMap['id']?.toString().trim();
      if (messageId == null || messageId.isEmpty) continue;

      final sender = map['sender'];
      String? senderUsername;
      if (sender is Map) {
        senderUsername = sender['username']?.toString().trim();
      }

      hits.add(
        ChatSearchHit(
          conversationId: map['conversation_id']?.toString().trim() ?? '',
          messageId: messageId,
          text: messageMap['text']?.toString().trim() ?? '',
          sentAt: DateTime.tryParse(messageMap['created_at']?.toString() ?? '')?.toLocal() ?? DateTime.now(),
          senderUsername: senderUsername,
        ),
      );
    }
    return hits;
  }

  @override
  Future<({List<ChatMessageReaction> reactions, List<String> myReactions})> toggleMessageReaction({
    required String messageId,
    required String emoji,
  }) async {
    final id = messageId.trim();
    final em = emoji.trim();
    if (id.isEmpty || em.isEmpty) {
      throw const ChatRepositoryException('Некорректная реакция');
    }

    final res = await _client.rpc(
      'toggle_message_reaction',
      params: {
        'p_message_id': id,
        'p_emoji': em,
      },
    );

    if (res is! Map) {
      throw const ChatRepositoryException('Не удалось обновить реакцию');
    }

    final map = Map<String, dynamic>.from(res);
    final reactionsRaw = map['reactions'];
    final myRaw = map['my_reactions'];
    final myList = myRaw is List
        ? [
            for (final item in myRaw)
              if (item?.toString().trim().isNotEmpty == true) item.toString().trim(),
          ]
        : const <String>[];

    final reactions = <ChatMessageReaction>[];
    if (reactionsRaw is List) {
      final mine = myList.toSet();
      for (final raw in reactionsRaw) {
        if (raw is! Map) continue;
        final reactionEmoji = raw['emoji']?.toString().trim() ?? '';
        if (reactionEmoji.isEmpty) continue;
        reactions.add(
          ChatMessageReaction(
            emoji: reactionEmoji,
            count: (raw['count'] as num?)?.toInt() ?? 0,
            isMine: mine.contains(reactionEmoji),
          ),
        );
      }
    }

    return (reactions: reactions, myReactions: myList);
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
