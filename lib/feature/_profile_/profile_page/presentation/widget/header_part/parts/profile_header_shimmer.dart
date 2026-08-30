import 'package:clover/core/extension/context.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/shared/app_shimmer.dart';
import 'package:flutter/material.dart';

/// Скелетон хедера профиля (без кнопок действий).
class ProfileHeaderShimmer extends StatelessWidget {
  const ProfileHeaderShimmer({super.key});

  static const double _figmaPaddingH = 16;
  static const double _figmaPaddingTop = 12;
  static const double _figmaPaddingBottom = 16;
  static const double _figmaAvatar = 86;
  static const double _figmaGapAvatarStats = 12;
  static const double _figmaStatValueW = 36;
  static const double _figmaStatValueH = 18;
  static const double _figmaStatValueRadius = 6;
  static const double _figmaStatGap = 8;
  static const double _figmaStatLabelW = 52;
  static const double _figmaStatLabelH = 12;
  static const double _figmaStatLabelRadius = 4;
  static const double _figmaGapAfterRow = 16;
  static const double _figmaLine1W = 170;
  static const double _figmaLine1H = 18;
  static const double _figmaLine1Radius = 8;
  static const double _figmaGapLine1Line2 = 10;
  static const double _figmaLine2W = 120;
  static const double _figmaLine2H = 14;
  static const double _figmaLine2Radius = 6;
  static const double _figmaGapBeforeBio = 12;
  static const double _figmaBioH = 48;
  static const double _figmaBioRadius = 8;

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              context.widthByContext(_figmaPaddingH),
              context.heightByContext(_figmaPaddingTop),
              context.widthByContext(_figmaPaddingH),
              context.heightByContext(_figmaPaddingBottom),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: context.heightByContext(_figmaAvatar),
                      height: context.heightByContext(_figmaAvatar),
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.white),
                    ),
                    SizedBox(width: context.widthByContext(_figmaGapAvatarStats)),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(
                          4,
                          (_) => Column(
                            children: [
                              Container(
                                width: context.widthByContext(_figmaStatValueW),
                                height: context.heightByContext(_figmaStatValueH),
                                decoration: BoxDecoration(
                                  color: AppColors.white,
                                  borderRadius: BorderRadius.circular(
                                    context.widthByContext(_figmaStatValueRadius),
                                  ),
                                ),
                              ),
                              SizedBox(height: context.heightByContext(_figmaStatGap)),
                              Container(
                                width: context.widthByContext(_figmaStatLabelW),
                                height: context.heightByContext(_figmaStatLabelH),
                                decoration: BoxDecoration(
                                  color: AppColors.white,
                                  borderRadius: BorderRadius.circular(
                                    context.widthByContext(_figmaStatLabelRadius),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: context.heightByContext(_figmaGapAfterRow)),
                _shimBar(
                  context,
                  width: context.widthByContext(_figmaLine1W),
                  height: context.heightByContext(_figmaLine1H),
                  radius: context.widthByContext(_figmaLine1Radius),
                ),
                SizedBox(height: context.heightByContext(_figmaGapLine1Line2)),
                _shimBar(
                  context,
                  width: context.widthByContext(_figmaLine2W),
                  height: context.heightByContext(_figmaLine2H),
                  radius: context.widthByContext(_figmaLine2Radius),
                ),
                SizedBox(height: context.heightByContext(_figmaGapBeforeBio)),
                _shimBar(
                  context,
                  fullWidth: true,
                  height: context.heightByContext(_figmaBioH),
                  radius: context.widthByContext(_figmaBioRadius),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _shimBar(
    BuildContext context, {
    bool fullWidth = false,
    double? width,
    required double height,
    required double radius,
  }) {
    final box = Container(
      width: fullWidth ? double.infinity : width,
      height: height,
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(radius)),
    );
    return fullWidth ? box : Align(alignment: Alignment.centerLeft, child: box);
  }
}
