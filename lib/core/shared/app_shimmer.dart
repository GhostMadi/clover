import 'package:clover/core/resources/colors.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Серебристый шиммер по умолчанию; оборачивает [child] (плейсхолдеры с заливкой).
class AppShimmer extends StatelessWidget {
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

  /// База — холодный серый, блик — почти белый «металлик».
  static const Color silverBase = Color(0xFFC8C8CC);
  static const Color silverHighlight = Color(0xFFF4F4F6);

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: baseColor ?? silverBase,
      highlightColor: highlightColor ?? silverHighlight,
      period: period,
      child: child,
    );
  }
}

/// Зона под фото без иконки «картинки» по центру: только форма кадра; при [shimmer] — лёгкий шиммер (загрузка).
class PostMediaFramePlaceholder extends StatelessWidget {
  const PostMediaFramePlaceholder({super.key, this.shimmer = true});

  final bool shimmer;

  @override
  Widget build(BuildContext context) {
    final box = SizedBox.expand(child: ColoredBox(color: AppColors.surfaceSoft));
    if (!shimmer) return box;
    return AppShimmer(child: box);
  }
}
