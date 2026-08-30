import 'package:clover/core/shared/platform/app_platform.dart';
import 'package:flutter/material.dart';

/// Масштабирование размеров из макета под текущий экран.
///
/// Значения [heightByContext] / [widthByContext] — это px из Figma.
/// Формула: `screenSize * (value / designSize)`.
///
/// Цвета и шрифты — см. `lib/core/resources/README.md` ([AppColors], [AppTextStyle]).
/// Платформа / нативность — см. `docs/code/ui/adaptive-widgets.md`.
extension ContextExtension on BuildContext {
  /// Высота артборда в макете (px).
  static const double designHeight = 1000;

  /// Ширина артборда в макете (px), обычно 375 для mobile.
  static const double designWidth = 375;

  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;

  double heightByContext(double value) => screenHeight * (value / designHeight);

  double widthByContext(double value) => screenWidth * (value / designWidth);

  double get bottomInset => MediaQuery.of(this).viewInsets.bottom;

  bool get isIOS => AppPlatform.isIOS;

  bool get isAndroid => AppPlatform.isAndroid;
}
