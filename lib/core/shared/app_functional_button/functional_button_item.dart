import 'package:flutter/material.dart';

/// Модель данных для описания функциональной кнопки в панели.
class FunctionalButtonItem {
  final IconData icon;
  final String? label;
  final VoidCallback onTap;
  final Color? customColor;
  final Color? iconColor;
  final Color? textColor;

  /// Обводка кнопки (например «Назад» — зелёная / синяя по сервису).
  final Color? borderColor;

  /// Если `true`, кнопка остаётся видимой при [AppFunctionalScreen.collapsed].
  final bool keepWhenCollapsed;

  /// Если `true`, вместо иконки показывается индикатор загрузки; нажатие отключено.
  final bool isLoading;

  const FunctionalButtonItem({
    required this.icon,
    required this.onTap,
    this.label,
    this.customColor,
    this.iconColor,
    this.textColor,
    this.borderColor,
    this.keepWhenCollapsed = false,
    this.isLoading = false,
  });
}
