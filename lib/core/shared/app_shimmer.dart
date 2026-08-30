import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/shared/platform/adaptive_widget.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Серебристый шиммер по умолчанию; оборачивает [child] (плейсхолдеры с заливкой).
class AppShimmer extends AdaptiveStatelessWidget {
  const AppShimmer({
    super.key,
    required this.child,
    this.baseColor,
    this.highlightColor,
    this.period = const Duration(milliseconds: 1200),
  });

  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;
  final Duration period;

  @override
  Widget buildMaterial(BuildContext context, AppPalette colors) => _build(colors);

  @override
  Widget buildCupertino(BuildContext context, AppPalette colors) => _build(colors);

  Widget _build(AppPalette colors) {
    return Shimmer.fromColors(
      baseColor: baseColor ?? colors.shimmerBase,
      highlightColor: highlightColor ?? colors.shimmerHighlight,
      period: period,
      child: child,
    );
  }
}

/// Зона под фото без иконки «картинки» по центру: только форма кадра; при [shimmer] — лёгкий шиммер (загрузка).
class PostMediaFramePlaceholder extends AdaptiveStatelessWidget {
  const PostMediaFramePlaceholder({super.key, this.shimmer = true});

  final bool shimmer;

  @override
  Widget buildMaterial(BuildContext context, AppPalette colors) => _build(colors);

  @override
  Widget buildCupertino(BuildContext context, AppPalette colors) => _build(colors);

  Widget _build(AppPalette colors) {
    final box = SizedBox.expand(child: ColoredBox(color: colors.surfaceSoft));
    if (!shimmer) return box;
    return AppShimmer(child: box);
  }
}
