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
  });

  final String id;
  final String username;
  final String lastMessage;
  final DateTime lastMessageAt;
  final bool isLastMessageMine;
  final bool isRead;
  final String? avatarUrl;
  final int unreadCount;

  bool get hasUnread => unreadCount > 0 || (!isLastMessageMine && !isRead);
}
