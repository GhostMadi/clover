import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:flutter/material.dart';

/// Ряд ★ 1–5. В mock-режиме можно сделать [onChanged] для выбора.
class PointReviewStars extends StatelessWidget {
  const PointReviewStars({
    super.key,
    required this.value,
    this.size = 18,
    this.onChanged,
  });

  final int value;
  final double size;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final interactive = onChanged != null;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var n = 1; n <= 5; n++) ...[
          if (n > 1) SizedBox(width: size * 0.15),
          GestureDetector(
            onTap: interactive ? () => onChanged!(n) : null,
            behavior: HitTestBehavior.opaque,
            child: Icon(
              n <= value ? AppIcons.starFilled.icon : AppIcons.starOutline.icon,
              size: size,
              color: n <= value ? colors.primary : colors.iconMuted,
            ),
          ),
        ],
      ],
    );
  }
}
