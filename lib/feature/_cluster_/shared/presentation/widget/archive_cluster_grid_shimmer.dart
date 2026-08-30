import 'package:clover/core/extension/context.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/shared/app_shimmer.dart';
import 'package:clover/feature/cluster/presentation/widget/cluster_card.dart';
import 'package:flutter/material.dart';

/// Шиммер сетки кластеров в архиве (квадратные карточки 1×1).
class ArchiveClusterGridShimmer extends StatelessWidget {
  const ArchiveClusterGridShimmer({super.key, this.itemCount = 4});

  final int itemCount;

  static const double _figmaGap = 12;
  static const double _figmaCardRadius = 20;

  @override
  Widget build(BuildContext context) {
    final gap = context.widthByContext(_figmaGap);
    final size = clusterCardWidth(context);
    final radius = context.widthByContext(_figmaCardRadius);

    return AppShimmer(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (var i = 0; i < itemCount; i++)
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(radius),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
