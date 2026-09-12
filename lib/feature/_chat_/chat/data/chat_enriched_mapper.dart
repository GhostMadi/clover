import 'dart:convert';

import 'package:clover/feature/_chat_/chat_page/data/models/chat_attendance_card.dart';
import 'package:clover/feature/_chat_/chat_page/data/models/chat_booking_staff_card.dart';
import 'package:clover/feature/_chat_/chat_page/data/models/chat_message.dart';
import 'package:clover/feature/_chat_/chat_page/data/models/chat_message_attachment.dart';
import 'package:clover/feature/_chat_/chat_page/data/models/chat_message_post_ref.dart';
import 'package:clover/feature/_chat_/chat_page/data/models/chat_message_reaction.dart';
import 'package:clover/feature/_chat_/chat_page/data/models/chat_message_reply_preview.dart';
import 'package:clover/feature/_chat_/message_page/data/models/message_chat_preview.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    final isGroup = type == 'group';

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
      type: type,
      isGroup: isGroup,
    );
  }

  static ChatMessage? toChatMessage(
    Map<String, dynamic> row, {
    required String currentUserId,
    SupabaseClient? storageClient,
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
    final postRef = _parsePostRef(row['post_ref']);
    final attachments = _parseAttachments(row['attachments'], storageClient: storageClient);
    final myReactions = _parseMyReactions(row['my_reactions']);
    final reactions = _parseReactions(row['reactions'], myReactions: myReactions);
    final replyPreview = _parseReplyPreview(row['reply_preview']);
    final rawText = message['text']?.toString();
    final attendanceCard = ChatAttendanceCard.fromRef(_asMap(row['attendance_card'])) ??
        ChatAttendanceCard.tryParse(rawText);
    final bookingStaffCard = ChatBookingStaffCard.fromRef(_asMap(row['booking_card']));
    final text = attendanceCard != null
        ? (attendanceCard.isInvite
            ? 'Приглашение · ${attendanceCard.workplaceName}'
            : 'Правила · ${attendanceCard.workplaceName}')
        : bookingStaffCard != null
            ? 'Приглашение в запись · ${bookingStaffCard.hostDisplayName}'
            : _messageText(message, attachments: attachments, postRef: postRef, kind: kind);

    return ChatMessage(
      id: id,
      text: text,
      sentAt: sentAt,
      isMine: isMine,
      isRead: isMine && message['read_by_peer'] == true,
      kind: kind,
      clientMessageId: message['client_message_id']?.toString(),
      isPending: isPending,
      postRef: postRef,
      attendanceCard: attendanceCard,
      bookingStaffCard: bookingStaffCard,
      attachments: attachments,
      reactions: reactions,
      myReactions: myReactions,
      replyPreview: replyPreview,
      editedAt: _parseDate(message['edited_at']),
    );
  }

  static ChatMessageReplyPreview? _parseReplyPreview(dynamic value) {
    final map = _asMap(value);
    if (map == null) return null;
    final preview = ChatMessageReplyPreview.fromJson(map);
    if (preview.id.isEmpty) return null;
    return preview;
  }

  static List<ChatMessageAttachment> _parseAttachments(
    dynamic value, {
    SupabaseClient? storageClient,
  }) {
    if (value is! List) return const [];

    final items = <ChatMessageAttachment>[];
    for (final raw in value) {
      if (raw is! Map) continue;
      final map = Map<String, dynamic>.from(raw);
      final bucket = map['bucket']?.toString().trim() ?? 'chat_media';
      final path = map['path']?.toString().trim() ?? '';
      if (path.isEmpty) continue;

      String? url = (map['public_url'] as String?)?.trim();
      if (url == null || url.isEmpty) {
        url = (map['url'] as String?)?.trim();
      }
      if ((url == null || url.isEmpty) && storageClient != null && bucket != 'r2') {
        url = storageClient.storage.from(bucket).getPublicUrl(path);
      }

      items.add(
        ChatMessageAttachment(
          id: map['id']?.toString().trim() ?? '',
          bucket: bucket,
          path: path,
          mime: map['mime']?.toString().trim(),
          sizeBytes: (map['size_bytes'] as num?)?.toInt(),
          url: url,
        ),
      );
    }
    return items;
  }

  static List<String> _parseMyReactions(dynamic value) {
    if (value is! List) return const [];
    return [
      for (final raw in value)
        if (raw?.toString().trim().isNotEmpty == true) raw.toString().trim(),
    ];
  }

  static List<ChatMessageReaction> _parseReactions(
    dynamic value, {
    required List<String> myReactions,
  }) {
    if (value is! List) return const [];

    final mine = myReactions.toSet();
    final items = <ChatMessageReaction>[];
    for (final raw in value) {
      if (raw is! Map) continue;
      final emoji = raw['emoji']?.toString().trim() ?? '';
      if (emoji.isEmpty) continue;
      items.add(
        ChatMessageReaction(
          emoji: emoji,
          count: (raw['count'] as num?)?.toInt() ?? 0,
          isMine: mine.contains(emoji),
        ),
      );
    }
    return items;
  }

  static ChatMessagePostRef? _parsePostRef(dynamic value) {
    final map = _asMap(value);
    if (map == null) return null;

    final postId = map['post_id']?.toString().trim();
    if (postId == null || postId.isEmpty) return null;

    final caption = map['caption']?.toString().trim();
    final title = map['title']?.toString().trim();
    final coverUrl = map['cover_url']?.toString().trim();

    return ChatMessagePostRef(
      postId: postId,
      caption: caption?.isNotEmpty == true ? caption : null,
      title: title?.isNotEmpty == true ? title : null,
      coverUrl: coverUrl?.isNotEmpty == true ? coverUrl : null,
    );
  }

  static String _messageText(
    Map<String, dynamic> message, {
    required List<ChatMessageAttachment> attachments,
    ChatMessagePostRef? postRef,
    required String kind,
  }) {
    if (kind == 'post_ref' || postRef != null) {
      final caption = postRef?.caption ?? message['text']?.toString().trim();
      return caption ?? '';
    }

    return displayText(message, attachmentCount: attachments.length);
  }

  static String previewText(Map<String, dynamic>? message) {
    if (message == null) return 'Нет сообщений';

    final kind = message['kind']?.toString() ?? 'text';
    final text = message['text']?.toString().trim();

    return switch (kind) {
      'media' => text?.isNotEmpty == true ? text! : 'Фото',
      'file' => text?.isNotEmpty == true ? text! : 'Файл',
      'post_ref' => 'Пост',
      'attendance_invite' => text?.isNotEmpty == true ? text! : 'Приглашение в команду',
      'attendance_rules' => text?.isNotEmpty == true ? text! : 'Правила посещаемости',
      'booking_staff_invite' => text?.isNotEmpty == true ? text! : 'Приглашение в запись',
      'system' => text?.isNotEmpty == true ? text! : 'Системное сообщение',
      _ => text?.isNotEmpty == true ? text! : 'Сообщение',
    };
  }

  static String displayText(
    Map<String, dynamic> message, {
    dynamic attachments,
    int attachmentCount = 0,
  }) {
    final kind = message['kind']?.toString() ?? 'text';
    final text = message['text']?.toString().trim();

    if (kind == 'text') {
      return text ?? '';
    }

    if (text?.isNotEmpty == true) {
      return text!;
    }

    return switch (kind) {
      'media' || 'file' => '',
      'post_ref' => 'Пост',
      'attendance_invite' => 'Приглашение в команду',
      'attendance_rules' => 'Правила посещаемости',
      'booking_staff_invite' => 'Приглашение в запись',
      'system' => 'Системное сообщение',
      _ => '',
    };
  }

  static Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    if (value is String && value.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }
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
