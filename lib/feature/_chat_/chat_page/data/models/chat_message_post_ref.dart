class ChatMessagePostRef {
  const ChatMessagePostRef({
    required this.postId,
    this.caption,
    this.title,
    this.coverUrl,
  });

  final String postId;
  final String? caption;
  final String? title;
  final String? coverUrl;

  Map<String, dynamic> toJson() {
    return {
      'post_id': postId,
      if (caption != null) 'caption': caption,
      if (title != null) 'title': title,
      if (coverUrl != null) 'cover_url': coverUrl,
    };
  }

  factory ChatMessagePostRef.fromJson(Map<String, dynamic> json) {
    return ChatMessagePostRef(
      postId: (json['post_id'] as String?)?.trim() ?? '',
      caption: (json['caption'] as String?)?.trim(),
      title: (json['title'] as String?)?.trim(),
      coverUrl: (json['cover_url'] as String?)?.trim(),
    );
  }
}
