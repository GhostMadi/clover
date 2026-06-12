import 'package:clover/feature/post/data/models/post_model.dart';

/// Пост + мини-данные автора и «сохранено мной» из enriched-RPC.
class PostFeedItem {
  const PostFeedItem({
    required this.post,
    this.authorUsername,
    this.authorAvatarUrl,
    this.myReaction,
    this.mySaved = false,
  });

  final PostModel post;
  final String? authorUsername;
  final String? authorAvatarUrl;

  /// `like` | `dislike` | null
  final String? myReaction;
  final bool mySaved;
}
