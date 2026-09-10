import 'package:clover/core/storage/domain/repositories/i_app_storage.dart';
import 'package:clover/core/storage/extensions/app_storage_extensions.dart';
import 'package:clover/feature/_chat_/chat_page/data/models/chat_message.dart';
import 'package:clover/feature/_chat_/message_page/data/models/message_chat_preview.dart';
import 'package:injectable/injectable.dart';

/// Watermark последней закэшированной головы треда (для согласования со списком).
class ChatThreadWatermark {
  const ChatThreadWatermark({
    required this.messageId,
    required this.sentAt,
  });

  final String messageId;
  final DateTime sentAt;

  Map<String, dynamic> toJson() => {
        'message_id': messageId,
        'sent_at': sentAt.toIso8601String(),
      };

  factory ChatThreadWatermark.fromJson(Map<String, dynamic> json) {
    return ChatThreadWatermark(
      messageId: (json['message_id'] as String?)?.trim() ?? '',
      sentAt: DateTime.tryParse(json['sent_at']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  bool get isValid => messageId.isNotEmpty;
}

/// Дисковый кэш списка чатов и сообщений (local-first UI).
@lazySingleton
class ChatLocalCache {
  ChatLocalCache(this._storage);

  final IAppStorage _storage;

  String _conversationsKey(String userId) => 'chat_conversations_${userId.trim()}';

  String _threadKey(String userId, String conversationId) =>
      'chat_thread_${userId.trim()}_${conversationId.trim()}';

  String _watermarkKey(String userId, String conversationId) =>
      'chat_thread_wm_${userId.trim()}_${conversationId.trim()}';

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

    try {
      return await _storage.readList<ChatMessage>(
        key: _threadKey(uid, cid),
        fromJson: (json) {
          if (json is! Map) throw FormatException('Expected map');
          return ChatMessage.fromJson(Map<String, dynamic>.from(json));
        },
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> writeMessages(String userId, String conversationId, List<ChatMessage> messages) async {
    final uid = userId.trim();
    final cid = conversationId.trim();
    if (uid.isEmpty || cid.isEmpty) return;

    try {
      final persisted = messages.where((m) => !m.isPending).toList(growable: false);
      await _storage.writeList(
        key: _threadKey(uid, cid),
        value: persisted,
        toJson: (message) => message.toJson(),
      );
      await _syncWatermark(uid, cid, persisted);
    } catch (_) {
      // Offline UI не должен падать из‑за кэша.
    }
  }

  /// Вмержить одно сообщение в кэш треда (idempotent по id / clientMessageId).
  Future<void> upsertMessage(String userId, String conversationId, ChatMessage message) async {
    final uid = userId.trim();
    final cid = conversationId.trim();
    if (uid.isEmpty || cid.isEmpty) return;
    if (message.isPending || message.id.trim().isEmpty) return;

    final existing = await readMessages(uid, cid) ?? const <ChatMessage>[];
    final next = _upsertInto(existing, message);
    await writeMessages(uid, cid, next);
  }

  Future<ChatThreadWatermark?> readWatermark(String userId, String conversationId) async {
    final uid = userId.trim();
    final cid = conversationId.trim();
    if (uid.isEmpty || cid.isEmpty) return null;

    try {
      final wm = await _storage.readObject<ChatThreadWatermark>(
        key: _watermarkKey(uid, cid),
        fromJson: ChatThreadWatermark.fromJson,
      );
      if (wm == null || !wm.isValid) return null;
      return wm;
    } catch (_) {
      return null;
    }
  }

  Future<void> writeWatermark(String userId, String conversationId, ChatThreadWatermark watermark) async {
    final uid = userId.trim();
    final cid = conversationId.trim();
    if (uid.isEmpty || cid.isEmpty || !watermark.isValid) return;

    try {
      await _storage.writeObject(
        key: _watermarkKey(uid, cid),
        value: watermark,
        toJson: (wm) => wm.toJson(),
      );
    } catch (_) {}
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
    await _storage.delete(key: _watermarkKey(uid, cid));
  }

  Future<void> _syncWatermark(String userId, String conversationId, List<ChatMessage> messages) async {
    if (messages.isEmpty) {
      await _storage.delete(key: _watermarkKey(userId, conversationId));
      return;
    }
    final sorted = [...messages]..sort(_compareMessages);
    final head = sorted.last;
    await writeWatermark(
      userId,
      conversationId,
      ChatThreadWatermark(messageId: head.id, sentAt: head.sentAt),
    );
  }

  static List<ChatMessage> _upsertInto(List<ChatMessage> existing, ChatMessage incoming) {
    final clientId = incoming.clientMessageId?.trim();
    final index = existing.indexWhere(
      (item) =>
          item.id == incoming.id ||
          (clientId != null &&
              clientId.isNotEmpty &&
              (item.clientMessageId == clientId || item.id == clientId)),
    );

    final next = [...existing];
    if (index >= 0) {
      next[index] = incoming.copyWith(
        isPending: false,
        clientMessageId: incoming.clientMessageId ?? existing[index].clientMessageId,
      );
    } else {
      next.add(incoming.copyWith(isPending: false));
    }
    next.sort(_compareMessages);
    return next;
  }

  static int _compareMessages(ChatMessage a, ChatMessage b) {
    final byTime = a.sentAt.compareTo(b.sentAt);
    if (byTime != 0) return byTime;
    return a.id.compareTo(b.id);
  }
}
