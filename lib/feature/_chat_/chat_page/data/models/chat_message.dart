import 'package:clover/feature/_chat_/chat_page/data/models/chat_message_post_ref.dart';

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
    this.postRef,
  });

  final String id;
  final String text;
  final DateTime sentAt;
  final bool isMine;
  final bool isRead;
  final String kind;
  final String? clientMessageId;
  final bool isPending;
  final ChatMessagePostRef? postRef;

  bool get isPostShare => kind == 'post_ref';

  bool get hasPostPreview => postRef != null && postRef!.postId.isNotEmpty;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'sent_at': sentAt.toUtc().toIso8601String(),
      'is_mine': isMine,
      'is_read': isRead,
      'kind': kind,
      if (clientMessageId != null) 'client_message_id': clientMessageId,
      'is_pending': isPending,
      if (postRef != null) 'post_ref': postRef!.toJson(),
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final postRefRaw = json['post_ref'];
    ChatMessagePostRef? postRef;
    if (postRefRaw is Map) {
      final parsed = ChatMessagePostRef.fromJson(Map<String, dynamic>.from(postRefRaw));
      if (parsed.postId.isNotEmpty) postRef = parsed;
    }

    return ChatMessage(
      id: (json['id'] as String?)?.trim() ?? '',
      text: (json['text'] as String?)?.trim() ?? '',
      sentAt: DateTime.tryParse(json['sent_at']?.toString() ?? '')?.toUtc() ?? DateTime.now().toUtc(),
      isMine: json['is_mine'] == true,
      isRead: json['is_read'] == true,
      kind: (json['kind'] as String?)?.trim().isNotEmpty == true ? json['kind'] as String : 'text',
      clientMessageId: (json['client_message_id'] as String?)?.trim(),
      isPending: json['is_pending'] == true,
      postRef: postRef,
    );
  }

  ChatMessage copyWith({
    String? id,
    String? text,
    DateTime? sentAt,
    bool? isMine,
    bool? isRead,
    String? kind,
    String? clientMessageId,
    bool? isPending,
    ChatMessagePostRef? postRef,
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
      postRef: postRef ?? this.postRef,
    );
  }
}
