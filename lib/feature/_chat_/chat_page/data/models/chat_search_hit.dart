class ChatSearchHit {
  const ChatSearchHit({
    required this.conversationId,
    required this.messageId,
    required this.text,
    required this.sentAt,
    this.senderUsername,
    this.conversationTitle,
  });

  final String conversationId;
  final String messageId;
  final String text;
  final DateTime sentAt;
  final String? senderUsername;
  final String? conversationTitle;

  String get preview {
    final body = text.trim();
    if (body.isEmpty) return 'Сообщение';
    return body.length > 120 ? '${body.substring(0, 120)}…' : body;
  }
}
