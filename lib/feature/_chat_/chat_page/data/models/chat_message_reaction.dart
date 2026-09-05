class ChatMessageReaction {
  const ChatMessageReaction({
    required this.emoji,
    required this.count,
    this.isMine = false,
  });

  final String emoji;
  final int count;
  final bool isMine;

  Map<String, dynamic> toJson() {
    return {
      'emoji': emoji,
      'count': count,
      'is_mine': isMine,
    };
  }

  factory ChatMessageReaction.fromJson(Map<String, dynamic> json) {
    return ChatMessageReaction(
      emoji: (json['emoji'] as String?)?.trim() ?? '',
      count: (json['count'] as num?)?.toInt() ?? 0,
      isMine: json['is_mine'] == true,
    );
  }

  ChatMessageReaction copyWith({
    String? emoji,
    int? count,
    bool? isMine,
  }) {
    return ChatMessageReaction(
      emoji: emoji ?? this.emoji,
      count: count ?? this.count,
      isMine: isMine ?? this.isMine,
    );
  }
}
