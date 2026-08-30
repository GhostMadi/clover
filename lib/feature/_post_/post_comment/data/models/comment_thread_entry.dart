import 'package:clover/feature/_post_/post_comment/data/models/comment_item.dart';

class CommentThreadEntry {
  const CommentThreadEntry({
    required this.root,
    this.replies = const [],
    this.repliesExpanded = false,
    this.repliesLoading = false,
  });

  final CommentItem root;
  final List<CommentItem> replies;
  final bool repliesExpanded;
  final bool repliesLoading;

  CommentThreadEntry copyWith({
    CommentItem? root,
    List<CommentItem>? replies,
    bool? repliesExpanded,
    bool? repliesLoading,
  }) {
    return CommentThreadEntry(
      root: root ?? this.root,
      replies: replies ?? this.replies,
      repliesExpanded: repliesExpanded ?? this.repliesExpanded,
      repliesLoading: repliesLoading ?? this.repliesLoading,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'root': root.toJson(),
      'replies': replies.map((reply) => reply.toJson()).toList(growable: false),
      'replies_expanded': repliesExpanded,
    };
  }

  factory CommentThreadEntry.fromJson(Map<String, dynamic> json) {
    final rootRaw = json['root'];
    if (rootRaw is! Map) {
      throw FormatException('CommentThreadEntry.root expected map');
    }

    final replies = <CommentItem>[];
    final rawReplies = json['replies'];
    if (rawReplies is List) {
      for (final item in rawReplies) {
        if (item is! Map) continue;
        replies.add(CommentItem.fromJson(Map<String, dynamic>.from(item)));
      }
    }

    return CommentThreadEntry(
      root: CommentItem.fromJson(Map<String, dynamic>.from(rootRaw)),
      replies: replies,
      repliesExpanded: json['replies_expanded'] == true,
    );
  }
}
