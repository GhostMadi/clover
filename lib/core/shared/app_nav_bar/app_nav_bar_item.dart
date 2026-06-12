import 'package:flutter/material.dart';

/// Tab descriptor for [AppNavBar].
@immutable
class AppNavBarItem {
  const AppNavBarItem({
    required this.icon,
    this.label,
  });

  final IconData icon;
  final String? label;
}
