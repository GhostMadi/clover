class ChatMessageReplyPreview {
  const ChatMessageReplyPreview({required this.id, this.text, this.kind = 'text', this.senderId});

  final String id;
  final String? text;
  final String kind;
  final String? senderId;

  String get previewText {
    final body = text?.trim();
    if (body != null && body.isNotEmpty) return body;
    return switch (kind) {
      'media' => 'Фото',
      'file' => 'Документ',
      'post_ref' => 'Пост',
      _ => 'Сообщение',
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (text != null) 'text': text,
      'kind': kind,
      if (senderId != null) 'sender_id': senderId,
    };
  }

  factory ChatMessageReplyPreview.fromJson(Map<String, dynamic> json) {
    return ChatMessageReplyPreview(
      id: (json['id'] as String?)?.trim() ?? '',
      text: (json['text'] as String?)?.trim(),
      kind: (json['kind'] as String?)?.trim().isNotEmpty == true ? json['kind'] as String : 'text',
      senderId: (json['sender_id'] as String?)?.trim(),
    );
  }
}
