import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/extension/context.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/shared/app_state.dart';
import 'package:clover/feature/_post_/post/data/models/post_model.dart';
import 'package:clover/feature/_post_/post/presentation/widget/post_cover_hero.dart';
import 'package:clover/core/post_media/post_media.dart';
import 'package:clover/feature/_post_/post/presentation/widget/post_image_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

/// Сетка постов: 6 колонок (2 визуальные), размер плитки зависит от формата фото.
class PostGrid extends StatelessWidget {
  const PostGrid({
    super.key,
    required this.posts,
    this.savedByPostId,
    this.onPostTap,
    this.emptyMessage = 'Нет публикаций',
    this.emptySubtitle,
    this.emptyIcon,
    this.onEmptyAction,
    this.emptyActionLabel = 'Создать',
    this.spacing = 3,
    this.crossAxisCount = PostMediaLayout.gridCrossAxisCount,
  });

  final List<PostModel> posts;
  final Map<String, bool>? savedByPostId;
  final ValueChanged<PostModel>? onPostTap;
  final String emptyMessage;
  final String? emptySubtitle;
  final IconData? emptyIcon;
  final VoidCallback? onEmptyAction;
  final String emptyActionLabel;
  final double spacing;
  final int crossAxisCount;

  static const double _figmaRadius = 7;

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return Padding(
        padding: EdgeInsets.fromLTRB(
          context.widthByContext(24),
          context.heightByContext(40),
          context.widthByContext(24),
          context.heightByContext(40),
        ),
        child: AppState(
          state: AppScreenState.empty,
          emptyIcon: emptyIcon ?? AppIcons.collections.icon,
          emptyTitle: emptyMessage,
          emptySubtitle: emptySubtitle,
          onEmptyAction: onEmptyAction,
          emptyActionLabel: emptyActionLabel,
          child: const SizedBox.shrink(),
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
      color: context.colors.surfaceSoft,
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
                    child: Icon(AppIcons.bookmarkFilled.icon, size: context.heightByContext(16), color: context.colors.textInverse),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
