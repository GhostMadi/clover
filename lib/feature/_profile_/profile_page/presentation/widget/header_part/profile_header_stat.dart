import 'package:clover/core/extension/context.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:flutter/material.dart';

/// Одна ячейка статистики: число + подпись.
class ProfileHeaderStat extends StatelessWidget {
  const ProfileHeaderStat({super.key, required this.value, required this.label});

  final String value;
  final String label;

  static const double _figmaValueFont = 18;
  static const double _figmaLabelFont = 12;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          value,
          textAlign: TextAlign.center,
          style: AppTextStyle.base(
            context.heightByContext(_figmaValueFont),
            color: AppColors.textColor,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyle.base(
            context.heightByContext(_figmaLabelFont),
            color: AppColors.subTextColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
