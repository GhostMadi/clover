import 'package:clover/core/extension/context.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/shared/app_shimmer.dart';
import 'package:clover/feature/_cluster_/cluster/presentation/widget/cluster_card.dart';
import 'package:flutter/material.dart';

/// Шиммер горизонтального списка кластеров.
class ClusterShimmer extends StatelessWidget {
  const ClusterShimmer({super.key, this.itemCount = 3});

  final int itemCount;

  static const double _figmaListPaddingH = 16;
  static const double _figmaListPaddingV = 4;
  static const double _figmaItemGap = 12;

  @override
  Widget build(BuildContext context) {
    final gap = context.widthByContext(_figmaItemGap);

    return AppShimmer(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        primary: false,
        padding: EdgeInsets.fromLTRB(
          context.widthByContext(_figmaListPaddingH),
          context.heightByContext(_figmaListPaddingV),
          context.widthByContext(_figmaListPaddingH),
          context.heightByContext(_figmaListPaddingV),
        ),
        child: Row(
          children: List.generate(
            itemCount,
            (i) => Padding(
              padding: EdgeInsets.only(right: i == itemCount - 1 ? 0 : gap),
              child: const _ClusterCardShim(),
            ),
          ),
        ),
      ),
    );
  }
}

class _ClusterCardShim extends StatelessWidget {
  const _ClusterCardShim();

  static const double _figmaCardRadius = 20;

  @override
  Widget build(BuildContext context) {
    final size = clusterCardWidth(context);
    final colors = AppColors.of(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(context.widthByContext(_figmaCardRadius)),
        color: colors.surfaceSoft,
      ),
    );
  }
}
