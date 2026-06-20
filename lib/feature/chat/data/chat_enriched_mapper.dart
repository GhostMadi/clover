import 'package:clover/feature/chat_page/data/models/chat_message.dart';
import 'package:clover/feature/message_page/data/models/message_chat_preview.dart';

abstract final class ChatEnrichedMapper {
  static MessageChatPreview? toConversationPreview(
    Map<String, dynamic> row, {
    required String currentUserId,
  }) {
    final conversationId = row['conversation_id']?.toString().trim();
    if (conversationId == null || conversationId.isEmpty) return null;

    final type = row['type']?.toString() ?? 'dm';
    final title = row['title']?.toString().trim();
    final otherUser = _asMap(row['other_user']);
    final lastMessage = _asMap(row['last_message']);
    final unreadCount = _asInt(row['unread_count']);

    final peerUsername = otherUser?['username']?.toString().trim();
    final displayName = switch (type) {
      'group' => (title?.isNotEmpty == true ? title! : 'Групповой чат'),
      _ => peerUsername?.isNotEmpty == true ? peerUsername! : 'Чат',
    };

    final senderId = lastMessage?['sender_id']?.toString().trim();
    final isLastMessageMine = senderId != null && senderId == currentUserId;
    final lastMessageAt = _parseDate(lastMessage?['created_at']) ?? _parseDate(row['created_at']) ?? DateTime.now();

    final isRead = isLastMessageMine
        ? (lastMessage?['read_by_peer'] == true)
        : unreadCount <= 0;

    return MessageChatPreview(
      id: conversationId,
      username: displayName,
      lastMessage: previewText(lastMessage),
      lastMessageAt: lastMessageAt,
      isLastMessageMine: isLastMessageMine,
      isRead: isRead,
      avatarUrl: otherUser?['avatar_url']?.toString(),
      unreadCount: unreadCount,
    );
  }

  static ChatMessage? toChatMessage(
    Map<String, dynamic> row, {
    required String currentUserId,
    bool isPending = false,
  }) {
    final message = _asMap(row['message']);
    if (message == null) return null;

    final id = message['id']?.toString().trim();
    if (id == null || id.isEmpty) return null;

    final senderId = message['sender_id']?.toString().trim() ?? '';
    final isMine = senderId == currentUserId;
    final sentAt = _parseDate(message['created_at']) ?? DateTime.now();
    final kind = message['kind']?.toString() ?? 'text';
    final text = displayText(message, attachments: row['attachments']);

    return ChatMessage(
      id: id,
      text: text,
      sentAt: sentAt,
      isMine: isMine,
      isRead: isMine && message['read_by_peer'] == true,
      kind: kind,
      clientMessageId: message['client_message_id']?.toString(),
      isPending: isPending,
    );
  }

  static String previewText(Map<String, dynamic>? message) {
    if (message == null) return 'Нет сообщений';

    final kind = message['kind']?.toString() ?? 'text';
    final text = message['text']?.toString().trim();

    return switch (kind) {
      'media' => text?.isNotEmpty == true ? text! : 'Фото',
      'file' => text?.isNotEmpty == true ? text! : 'Документ',
      'post_ref' => 'Пост',
      'system' => text?.isNotEmpty == true ? text! : 'Системное сообщение',
      _ => text?.isNotEmpty == true ? text! : 'Сообщение',
    };
  }

  static String displayText(
    Map<String, dynamic> message, {
    dynamic attachments,
  }) {
    final kind = message['kind']?.toString() ?? 'text';
    final text = message['text']?.toString().trim();

    if (kind == 'text') {
      return text ?? '';
    }

    if (text?.isNotEmpty == true) {
      return text!;
    }

    final attachCount = switch (attachments) {
      List<dynamic> list => list.length,
      _ => 0,
    };

    return switch (kind) {
      'media' => attachCount > 1 ? 'Фото ($attachCount)' : 'Фото',
      'file' => attachCount > 1 ? 'Документы ($attachCount)' : 'Документ',
      'post_ref' => 'Пост',
      'system' => 'Системное сообщение',
      _ => 'Сообщение',
    };
  }

  static Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is DateTime) return value;
    final raw = value?.toString().trim();
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }
}
