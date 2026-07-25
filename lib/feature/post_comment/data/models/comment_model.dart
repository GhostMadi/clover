class CommentModel {
  const CommentModel({
    required this.id,
    required this.postId,
    required this.userId,
    required this.text,
    required this.likesCount,
    required this.dislikesCount,
    required this.repliesCount,
    required this.createdAt,
    this.parentCommentId,
    this.editedAt,
    this.isDeleted = false,
  });

  final String id;
  final String postId;
  final String userId;
  final String text;
  final String? parentCommentId;
  final int likesCount;
  final int dislikesCount;
  final int repliesCount;
  final DateTime createdAt;
  final DateTime? editedAt;
  final bool isDeleted;

  bool get isRoot => parentCommentId == null || parentCommentId!.trim().isEmpty;

  CommentModel copyWith({
    String? text,
    int? likesCount,
    int? dislikesCount,
    int? repliesCount,
  }) {
    return CommentModel(
      id: id,
      postId: postId,
      userId: userId,
      text: text ?? this.text,
      parentCommentId: parentCommentId,
      likesCount: likesCount ?? this.likesCount,
      dislikesCount: dislikesCount ?? this.dislikesCount,
      repliesCount: repliesCount ?? this.repliesCount,
      createdAt: createdAt,
      editedAt: editedAt,
      isDeleted: isDeleted,
    );
  }

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: (json['id'] as String?)?.trim() ?? '',
      postId: (json['post_id'] as String?)?.trim() ?? '',
      userId: (json['user_id'] as String?)?.trim() ?? '',
      text: (json['text'] as String?)?.trim() ?? '',
      parentCommentId: (json['parent_comment_id'] as String?)?.trim(),
      likesCount: (json['likes_count'] as num?)?.toInt() ?? 0,
      dislikesCount: (json['dislikes_count'] as num?)?.toInt() ?? 0,
      repliesCount: (json['replies_count'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '')?.toUtc() ?? DateTime.now().toUtc(),
      editedAt: json['edited_at'] == null
          ? null
          : DateTime.tryParse(json['edited_at'].toString())?.toUtc(),
      isDeleted: json['is_deleted'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'post_id': postId,
      'user_id': userId,
      'text': text,
      if (parentCommentId != null) 'parent_comment_id': parentCommentId,
      'likes_count': likesCount,
      'dislikes_count': dislikesCount,
      'replies_count': repliesCount,
      'created_at': createdAt.toUtc().toIso8601String(),
      if (editedAt != null) 'edited_at': editedAt!.toUtc().toIso8601String(),
      'is_deleted': isDeleted,
    };
  }
}
