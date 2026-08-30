import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/shared/platform/adaptive_widget.dart';
import 'package:flutter/material.dart';

/// Единый refresh-контрол проекта (визуально совпадает с `AppCircularProgressIndicator`).
class AppRefresh extends AdaptiveStatelessWidget {
  const AppRefresh({
    super.key,
    required this.onRefresh,
    required this.child,
    this.color,
    this.backgroundColor,
    this.strokeWidth = 2.5,
    this.displacement = 40.0,
    this.edgeOffset = 0.0,
  });

  final Future<void> Function() onRefresh;
  final Widget child;

  final Color? color;
  final Color? backgroundColor;
  final double strokeWidth;
  final double displacement;
  final double edgeOffset;

  @override
  Widget buildMaterial(BuildContext context, AppPalette colors) => _build(colors);

  @override
  Widget buildCupertino(BuildContext context, AppPalette colors) => _build(colors);

  Widget _build(AppPalette colors) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: color ?? colors.primary,
      backgroundColor: backgroundColor ?? colors.surface,
      strokeWidth: strokeWidth,
      displacement: displacement,
      edgeOffset: edgeOffset,
      child: child,
    );
  }
}
