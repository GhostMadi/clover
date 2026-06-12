import 'package:flutter/material.dart';
import 'package:clover/core/resources/colors.dart';

/// Единый refresh-контрол проекта (визуально совпадает с `AppCircularProgressIndicator`).
class AppRefresh extends StatelessWidget {
  const AppRefresh({
    super.key,
    required this.onRefresh,
    required this.child,
    this.color,
    this.backgroundColor,
    this.strokeWidth = 2.5,
    this.displacement = 40.0,
    this.edgeOffset = 0.0,
    // this.notificationPredicate = defaultScrollNotificationPredicate,
  });

  final Future<void> Function() onRefresh;
  final Widget child;

  final Color? color;
  final Color? backgroundColor;
  final double strokeWidth;
  final double displacement;
  final double edgeOffset;
  // final ScrollNotificationPredicate notificationPredicate;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: color ?? AppColors.primary,
      backgroundColor: backgroundColor ?? Colors.white,
      strokeWidth: strokeWidth,
      displacement: displacement,
      edgeOffset: edgeOffset,
      // notificationPredicate: notificationPredicate,
      child: child,
    );
  }
}
