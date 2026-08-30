import 'package:clover/core/extension/context.dart';
import 'package:clover/core/post_media/post_aspect_ratio.dart';
import 'package:clover/core/post_media/post_media_layout.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/shared/app_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

/// Шиммер masonry-сетки постов (как [PostGrid]).
class PostFeedShimmer extends StatelessWidget {
  const PostFeedShimmer({super.key, this.tileCount = 9});

  final int tileCount;

  static const double _figmaSpacing = 3;
  static const double _figmaRadius = 7;

  static const _pattern = [
    PostAspectRatio.square1x1,
    PostAspectRatio.standard4x3,
    PostAspectRatio.portrait9x16,
    PostAspectRatio.square1x1,
    PostAspectRatio.landscape16x9,
    PostAspectRatio.standard4x3,
    PostAspectRatio.square1x1,
    PostAspectRatio.portrait9x16,
    PostAspectRatio.standard4x3,
  ];

  @override
  Widget build(BuildContext context) {
    final spacing = context.widthByContext(_figmaSpacing);
    final radius = context.widthByContext(_figmaRadius);
    final aspects = [
      for (var i = 0; i < tileCount; i++) _pattern[i % _pattern.length],
    ];
    final spans = PostMediaLayout.computeGridSpans(aspects);

    return AppShimmer(
      child: StaggeredGrid.count(
        crossAxisCount: PostMediaLayout.gridCrossAxisCount,
        mainAxisSpacing: spacing,
        crossAxisSpacing: spacing,
        children: [
          for (var i = 0; i < spans.length; i++)
            StaggeredGridTile.count(
              crossAxisCellCount: spans[i].cross,
              mainAxisCellCount: spans[i].main,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: context.colors.white,
                  borderRadius: BorderRadius.circular(radius),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
