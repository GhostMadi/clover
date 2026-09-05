class MessageChatPreview {
  const MessageChatPreview({
    required this.id,
    required this.username,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.isLastMessageMine,
    required this.isRead,
    this.avatarUrl,
    this.unreadCount = 0,
    this.type = 'dm',
    this.isGroup = false,
  });

  final String id;
  final String username;
  final String lastMessage;
  final DateTime lastMessageAt;
  final bool isLastMessageMine;
  final bool isRead;
  final String? avatarUrl;
  final int unreadCount;
  final String type;
  final bool isGroup;

  bool get hasUnread => unreadCount > 0 || (!isLastMessageMine && !isRead);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'last_message': lastMessage,
      'last_message_at': lastMessageAt.toUtc().toIso8601String(),
      'is_last_message_mine': isLastMessageMine,
      'is_read': isRead,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      'unread_count': unreadCount,
      'type': type,
      'is_group': isGroup,
    };
  }

  factory MessageChatPreview.fromJson(Map<String, dynamic> json) {
    final type = (json['type'] as String?)?.trim().isNotEmpty == true ? json['type'] as String : 'dm';
    return MessageChatPreview(
      id: (json['id'] as String?)?.trim() ?? '',
      username: (json['username'] as String?)?.trim() ?? '',
      lastMessage: (json['last_message'] as String?)?.trim() ?? '',
      lastMessageAt:
          DateTime.tryParse(json['last_message_at']?.toString() ?? '')?.toUtc() ?? DateTime.now().toUtc(),
      isLastMessageMine: json['is_last_message_mine'] == true,
      isRead: json['is_read'] == true,
      avatarUrl: (json['avatar_url'] as String?)?.trim(),
      unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
      type: type,
      isGroup: json['is_group'] == true || type == 'group',
    );
  }
}
