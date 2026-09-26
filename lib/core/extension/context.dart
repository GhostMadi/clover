import 'package:clover/core/locale/app_date_format.dart';
import 'package:clover/core/shared/platform/app_platform.dart';
import 'package:clover/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Масштабирование размеров из макета под текущий экран.
///
/// Значения [heightByContext] / [widthByContext] — это px из Figma.
/// Формула: `screenSize * (value / designSize)`.
///
/// Цвета и шрифты — см. `lib/core/resources/README.md` ([AppColors], [AppTextStyle]).
/// Платформа / нативность — см. `docs/code/ui/adaptive-widgets.md`.
/// Строки UI — [l10n] (`docs/business/app-localization.md`).
/// Даты / месяцы / дни недели — [dateFormat] (intl), не ARB.
extension ContextExtension on BuildContext {
  /// Высота артборда в макете (px).
  static const double designHeight = 1000;

  /// Ширина артборда в макете (px), обычно 375 для mobile.
  static const double designWidth = 375;

  AppLocalizations get l10n => AppLocalizations.of(this);

  /// Locale-aware date labels ([intl]).
  AppDateFormat get dateFormat => AppDateFormat(l10n.localeName);

  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;

  double heightByContext(double value) {
    final scale = (screenHeight / designHeight).clamp(0.75, 1.2);
    return value * scale;
  }

  /// На iPad / широких экранах не раздуваем Figma-размеры до полной ширины
  /// (иначе сетка профиля и кластеры декодируют огромные картинки → OOM).
  double widthByContext(double value) {
    final scale = (screenWidth / designWidth).clamp(0.75, 1.2);
    return value * scale;
  }

  double get bottomInset => MediaQuery.of(this).viewInsets.bottom;

  bool get isIOS => AppPlatform.isIOS;

  bool get isAndroid => AppPlatform.isAndroid;
}
