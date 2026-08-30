import 'package:clover/feature/_post_/post_comment/data/models/comment_model.dart';

/// Комментарий + автор + моя реакция из enriched-RPC.
class CommentItem {
  const CommentItem({
    required this.comment,
    this.authorUsername,
    this.authorAvatarUrl,
    this.myKind,
  });

  final CommentModel comment;
  final String? authorUsername;
  final String? authorAvatarUrl;

  /// `like` | `dislike` | null
  final String? myKind;

  bool get isLiked => myKind == 'like';

  CommentItem copyWith({
    CommentModel? comment,
    String? authorUsername,
    String? authorAvatarUrl,
    String? myKind,
    bool clearMyKind = false,
  }) {
    return CommentItem(
      comment: comment ?? this.comment,
      authorUsername: authorUsername ?? this.authorUsername,
      authorAvatarUrl: authorAvatarUrl ?? this.authorAvatarUrl,
      myKind: clearMyKind ? null : (myKind ?? this.myKind),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'comment': comment.toJson(),
      if (authorUsername != null) 'author_username': authorUsername,
      if (authorAvatarUrl != null) 'author_avatar_url': authorAvatarUrl,
      if (myKind != null) 'my_kind': myKind,
    };
  }

  factory CommentItem.fromJson(Map<String, dynamic> json) {
    final commentRaw = json['comment'];
    if (commentRaw is! Map) {
      throw FormatException('CommentItem.comment expected map');
    }

    String? myKind;
    final kindRaw = json['my_kind'];
    if (kindRaw is String) {
      final k = kindRaw.trim();
      if (k == 'like' || k == 'dislike') myKind = k;
    }

    return CommentItem(
      comment: CommentModel.fromJson(Map<String, dynamic>.from(commentRaw)),
      authorUsername: (json['author_username'] as String?)?.trim(),
      authorAvatarUrl: (json['author_avatar_url'] as String?)?.trim(),
      myKind: myKind,
    );
  }
}
