import 'package:flutter/material.dart';

String postCoverHeroTag(String postId) => 'post_cover_${postId.trim()}';

/// Обложка поста с Hero-переходом (сетка профиля → экран поста).
class PostCoverHero extends StatelessWidget {
  const PostCoverHero({
    super.key,
    required this.postId,
    required this.borderRadius,
    required this.child,
  });

  final String postId;
  final BorderRadius borderRadius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: postCoverHeroTag(postId),
      child: Material(
        type: MaterialType.transparency,
        clipBehavior: Clip.antiAlias,
        borderRadius: borderRadius,
        child: child,
      ),
    );
  }
}
