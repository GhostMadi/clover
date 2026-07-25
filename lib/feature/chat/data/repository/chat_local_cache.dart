import 'package:clover/core/storage/domain/repositories/i_app_storage.dart';
import 'package:clover/core/storage/extensions/app_storage_extensions.dart';
import 'package:clover/feature/chat_page/data/models/chat_message.dart';
import 'package:clover/feature/message_page/data/models/message_chat_preview.dart';
import 'package:injectable/injectable.dart';

/// Дисковый кэш списка чатов и сообщений (local-first UI).
@lazySingleton
class ChatLocalCache {
  ChatLocalCache(this._storage);

  final IAppStorage _storage;

  String _conversationsKey(String userId) => 'chat_conversations_${userId.trim()}';

  String _threadKey(String userId, String conversationId) =>
      'chat_thread_${userId.trim()}_${conversationId.trim()}';

  Future<List<MessageChatPreview>?> readConversations(String userId) async {
    final id = userId.trim();
    if (id.isEmpty) return null;

    return _storage.readList<MessageChatPreview>(
      key: _conversationsKey(id),
      fromJson: (json) {
        if (json is! Map) throw FormatException('Expected map');
        return MessageChatPreview.fromJson(Map<String, dynamic>.from(json));
      },
    );
  }

  Future<void> writeConversations(String userId, List<MessageChatPreview> chats) async {
    final id = userId.trim();
    if (id.isEmpty) return;

    await _storage.writeList(
      key: _conversationsKey(id),
      value: chats,
      toJson: (chat) => chat.toJson(),
    );
  }

  Future<List<ChatMessage>?> readMessages(String userId, String conversationId) async {
    final uid = userId.trim();
    final cid = conversationId.trim();
    if (uid.isEmpty || cid.isEmpty) return null;

    return _storage.readList<ChatMessage>(
      key: _threadKey(uid, cid),
      fromJson: (json) {
        if (json is! Map) throw FormatException('Expected map');
        return ChatMessage.fromJson(Map<String, dynamic>.from(json));
      },
    );
  }

  Future<void> writeMessages(String userId, String conversationId, List<ChatMessage> messages) async {
    final uid = userId.trim();
    final cid = conversationId.trim();
    if (uid.isEmpty || cid.isEmpty) return;

    await _storage.writeList(
      key: _threadKey(uid, cid),
      value: messages,
      toJson: (message) => message.toJson(),
    );
  }

  Future<void> clearConversations(String userId) async {
    final id = userId.trim();
    if (id.isEmpty) return;
    await _storage.delete(key: _conversationsKey(id));
  }

  Future<void> clearThread(String userId, String conversationId) async {
    final uid = userId.trim();
    final cid = conversationId.trim();
    if (uid.isEmpty || cid.isEmpty) return;
    await _storage.delete(key: _threadKey(uid, cid));
  }
}
