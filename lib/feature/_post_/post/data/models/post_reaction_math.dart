import 'package:clover/feature/_post_/post/data/models/post_model.dart';

/// Пересчёт счётчиков при смене реакции (`like` | `dislike` | null).
abstract final class PostReactionMath {
  PostReactionMath._();

  static PostModel apply({
    required PostModel post,
    required String? from,
    required String? to,
  }) {
    var likes = post.likesCount;
    var dislikes = post.dislikesCount;

    if (from == 'like') likes--;
    if (from == 'dislike') dislikes--;
    if (to == 'like') likes++;
    if (to == 'dislike') dislikes++;

    return post.copyWith(
      likesCount: likes < 0 ? 0 : likes,
      dislikesCount: dislikes < 0 ? 0 : dislikes,
    );
  }
}
