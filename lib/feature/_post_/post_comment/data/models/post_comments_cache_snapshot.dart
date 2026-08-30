import 'package:clover/feature/_post_/post_comment/data/models/comment_thread_entry.dart';

class PostCommentsCacheSnapshot {
  const PostCommentsCacheSnapshot({
    required this.threads,
    required this.hasMore,
  });

  final List<CommentThreadEntry> threads;
  final bool hasMore;

  Map<String, dynamic> toJson() {
    return {
      'threads': threads.map((thread) => thread.toJson()).toList(growable: false),
      'has_more': hasMore,
    };
  }

  factory PostCommentsCacheSnapshot.fromJson(Map<String, dynamic> json) {
    final rawThreads = json['threads'];
    final threads = <CommentThreadEntry>[];
    if (rawThreads is List) {
      for (final item in rawThreads) {
        if (item is! Map) continue;
        threads.add(CommentThreadEntry.fromJson(Map<String, dynamic>.from(item)));
      }
    }

    return PostCommentsCacheSnapshot(
      threads: threads,
      hasMore: json['has_more'] == true,
    );
  }
}
