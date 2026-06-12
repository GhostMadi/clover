import 'package:clover/core/extension/context.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/shared/app_shimmer.dart';
import 'package:clover/feature/cluster/presentation/widget/cluster_card.dart';
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

  static const double _figmaCardRadius = 18;
  static const double _figmaPadding = 10;
  static const double _figmaThumb = 52;
  static const double _figmaThumbRadius = 11;
  static const double _figmaGapThumb = 10;
  static const double _figmaLine1Height = 14;
  static const double _figmaLine1Radius = 6;
  static const double _figmaLineGap = 8;
  static const double _figmaLine2Width = 90;
  static const double _figmaLine2Height = 10;
  static const double _figmaLine2Radius = 6;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: clusterCardWidth(context),
      padding: EdgeInsets.all(context.widthByContext(_figmaPadding)),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(context.widthByContext(_figmaCardRadius)),
        color: AppColors.white,
      ),
      child: Row(
        children: [
          _Box(
            width: context.heightByContext(_figmaThumb),
            height: context.heightByContext(_figmaThumb),
            radius: context.widthByContext(_figmaThumbRadius),
          ),
          SizedBox(width: context.widthByContext(_figmaGapThumb)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Box(
                  width: double.infinity,
                  height: context.heightByContext(_figmaLine1Height),
                  radius: context.widthByContext(_figmaLine1Radius),
                ),
                SizedBox(height: context.heightByContext(_figmaLineGap)),
                _Box(
                  width: context.widthByContext(_figmaLine2Width),
                  height: context.heightByContext(_figmaLine2Height),
                  radius: context.widthByContext(_figmaLine2Radius),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Box extends StatelessWidget {
  const _Box({required this.width, required this.height, required this.radius});

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width.isFinite ? width : null,
      height: height,
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(radius)),
    );
  }
}
