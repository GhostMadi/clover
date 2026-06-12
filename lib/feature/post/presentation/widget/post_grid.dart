import 'package:clover/core/extension/context.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/feature/post/data/models/post_model.dart';
import 'package:clover/feature/post/presentation/widget/post_cover_hero.dart';
import 'package:clover/core/post_media/post_media.dart';
import 'package:clover/feature/post/presentation/widget/post_image_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

/// Сетка постов: 6 колонок (2 визуальные), размер плитки зависит от формата фото.
class PostGrid extends StatelessWidget {
  const PostGrid({
    super.key,
    required this.posts,
    this.savedByPostId,
    this.onPostTap,
    this.spacing = 3,
    this.crossAxisCount = PostMediaLayout.gridCrossAxisCount,
  });

  final List<PostModel> posts;
  final Map<String, bool>? savedByPostId;
  final ValueChanged<PostModel>? onPostTap;
  final double spacing;
  final int crossAxisCount;

  static const double _figmaRadius = 7;

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return Padding(
        padding: EdgeInsets.fromLTRB(
          context.widthByContext(24),
          context.heightByContext(32),
          context.widthByContext(24),
          context.heightByContext(32),
        ),
        child: Text(
          'нет публикаций',
          textAlign: TextAlign.center,
          style: AppTextStyle.base(context.heightByContext(14), color: AppColors.subTextColor, height: 1.35),
        ),
      );
    }

    final gap = context.widthByContext(spacing);
    final radius = context.widthByContext(_figmaRadius);
    final spans = PostMediaLayout.computeGridSpans(
      posts.map((p) => p.coverMedia?.aspectRatio ?? PostAspectRatio.square1x1).toList(),
      crossAxisCount: crossAxisCount,
    );

    return StaggeredGrid.count(
      crossAxisCount: crossAxisCount,
      mainAxisSpacing: gap,
      crossAxisSpacing: gap,
      children: [
        for (var i = 0; i < posts.length; i++)
          if (i < spans.length)
            StaggeredGridTile.count(
              crossAxisCellCount: spans[i].cross,
              mainAxisCellCount: spans[i].main,
              child: _PostGridCell(
                post: posts[i],
                imageUrl: posts[i].coverMedia?.previewImageUrl,
                blurHash: posts[i].coverMedia?.blurHash,
                borderRadius: radius,
                isSaved: savedByPostId?[posts[i].id] ?? false,
                onTap: onPostTap == null ? null : () => onPostTap!(posts[i]),
              ),
            ),
      ],
    );
  }
}

class _PostGridCell extends StatelessWidget {
  const _PostGridCell({
    required this.post,
    required this.imageUrl,
    required this.blurHash,
    required this.borderRadius,
    required this.isSaved,
    this.onTap,
  });

  final PostModel post;
  final String? imageUrl;
  final String? blurHash;
  final double borderRadius;
  final bool isSaved;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceSoft,
      borderRadius: BorderRadius.circular(borderRadius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            PostCoverHero(
              postId: post.id,
              borderRadius: BorderRadius.circular(borderRadius),
              child: imageUrl == null
                  ? PostImagePlaceholder(borderRadius: 0)
                  : PostImageTile(imageUrl: imageUrl, blurHash: blurHash, borderRadius: 0),
            ),
            if (isSaved)
              Positioned(
                top: context.heightByContext(6),
                right: context.widthByContext(6),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(context.widthByContext(6)),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(context.widthByContext(4)),
                    child: Icon(Icons.bookmark, size: context.heightByContext(16), color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
