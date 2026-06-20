class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.text,
    required this.sentAt,
    required this.isMine,
    this.isRead = false,
    this.kind = 'text',
    this.clientMessageId,
    this.isPending = false,
  });

  final String id;
  final String text;
  final DateTime sentAt;
  final bool isMine;
  final bool isRead;
  final String kind;
  final String? clientMessageId;
  final bool isPending;

  ChatMessage copyWith({
    String? id,
    String? text,
    DateTime? sentAt,
    bool? isMine,
    bool? isRead,
    String? kind,
    String? clientMessageId,
    bool? isPending,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      sentAt: sentAt ?? this.sentAt,
      isMine: isMine ?? this.isMine,
      isRead: isRead ?? this.isRead,
      kind: kind ?? this.kind,
      clientMessageId: clientMessageId ?? this.clientMessageId,
      isPending: isPending ?? this.isPending,
    );
  }
}
