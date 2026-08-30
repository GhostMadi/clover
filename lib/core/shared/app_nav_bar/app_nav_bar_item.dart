import 'package:flutter/material.dart';

/// Tab descriptor for [AppNavBar].
@immutable
class AppNavBarItem {
  const AppNavBarItem({
    required this.icon,
    this.behindIcon,
    this.label,
  });

  /// Основная (передняя) иконка.
  final IconData icon;

  /// Опциональный «слой сзади» — намёк, что за этим табом есть ещё экран
  /// (например лента ↔ карта на Home).
  final IconData? behindIcon;

  final String? label;
}
