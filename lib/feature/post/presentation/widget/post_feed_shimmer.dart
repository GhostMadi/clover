import 'package:clover/core/extension/context.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/shared/app_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

/// Шиммер masonry-сетки постов (как [PostGrid]).
class PostFeedShimmer extends StatelessWidget {
  const PostFeedShimmer({super.key, this.tileCount = 8});

  final int tileCount;

  static const double _figmaSpacing = 2;
  static const double _figmaRadius = 12;

  @override
  Widget build(BuildContext context) {
    final spacing = context.widthByContext(_figmaSpacing);
    final radius = context.widthByContext(_figmaRadius);

    return AppShimmer(
      child: StaggeredGrid.count(
        crossAxisCount: 2,
        mainAxisSpacing: spacing,
        crossAxisSpacing: spacing,
        children: [
          for (var i = 0; i < tileCount; i++)
            StaggeredGridTile.count(
              crossAxisCellCount: i % 7 == 2 ? 2 : 1,
              mainAxisCellCount: i % 5 == 1 ? 2 : 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(radius),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
