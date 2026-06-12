import 'package:flutter/material.dart';

/// Модель данных для описания функциональной кнопки в панели.
class FunctionalButtonItem {
  final IconData icon;
  final String? label;
  final VoidCallback onTap;
  final Color? customColor;
  final Color? iconColor;
  final Color? textColor;

  /// Если `true`, кнопка остаётся видимой при [AppFunctionalScreen.collapsed].
  final bool keepWhenCollapsed;

  const FunctionalButtonItem({
    required this.icon,
    required this.onTap,
    this.label,
    this.customColor,
    this.iconColor,
    this.textColor,
    this.keepWhenCollapsed = false,
  });
}
