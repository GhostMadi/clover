import 'package:flutter/material.dart' show ThemeMode;

/// User preference: follow system, force light, or force dark.
enum AppThemeMode {
  system('system'),
  light('light'),
  dark('dark');

  const AppThemeMode(this.storageValue);

  final String storageValue;

  static AppThemeMode fromStorage(String? raw) {
    final value = raw?.trim();
    return AppThemeMode.values.firstWhere(
      (mode) => mode.storageValue == value,
      orElse: () => AppThemeMode.system,
    );
  }

  ThemeMode get material => switch (this) {
        AppThemeMode.system => ThemeMode.system,
        AppThemeMode.light => ThemeMode.light,
        AppThemeMode.dark => ThemeMode.dark,
      };

  String get labelRu => switch (this) {
        AppThemeMode.system => 'Системная',
        AppThemeMode.light => 'Светлая',
        AppThemeMode.dark => 'Тёмная',
      };
}
