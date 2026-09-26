import 'package:flutter/material.dart';

/// Supported app languages (UI). Backend catalogs stay EN keys.
enum AppLocale {
  ru('ru'),
  en('en'),
  kk('kk');

  const AppLocale(this.languageCode);

  final String languageCode;

  Locale get locale => Locale(languageCode);

  /// Native endonym for the language picker (not translated).
  String get endonym => switch (this) {
        AppLocale.ru => 'Русский',
        AppLocale.en => 'English',
        AppLocale.kk => 'Қазақша',
      };

  static AppLocale fromStorage(String? raw) {
    final code = raw?.trim().toLowerCase();
    return AppLocale.values.firstWhere(
      (locale) => locale.languageCode == code,
      orElse: () => AppLocale.ru,
    );
  }

  static AppLocale fromDevice(Locale? device) {
    final code = device?.languageCode.toLowerCase();
    return AppLocale.values.firstWhere(
      (locale) => locale.languageCode == code,
      orElse: () => AppLocale.ru,
    );
  }
}
