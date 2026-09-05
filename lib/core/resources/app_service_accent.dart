import 'package:clover/core/theme/app_palette.dart';
import 'package:flutter/material.dart';

/// Продуктовый сервис с собственным визуальным акцентом (CTA, иконки, мягкие фоны).
///
/// Бренд приложения ([AppPalette.primary]) — зелёный; каждый сервис внутри продукта
/// получает свой узнаваемый цвет через [AppServiceAccent].
///
/// Чтобы сменить цвет сервиса — правь только [serviceAccent] и токены в [AppPalette]
/// (запись: `functionalSoftYellow` = `#FDF08B`).
enum AppServiceKind {
  /// Посещаемость — синий.
  attendance,

  /// Запись — жёлтый (`functionalSoftYellow` / `#FDF08B`).
  booking,

  /// Бонусы — оранжевый.
  bonus,
}

/// Цветовой набор сервиса: CTA, обводка кнопки, мягкий фон, иконки.
class AppServiceAccent {
  const AppServiceAccent({
    required this.cta,
    required this.ctaForeground,
    required this.ctaBorder,
    required this.soft,
    required this.icon,
  });

  /// Фон основной кнопки сервиса.
  final Color cta;

  /// Текст / иконка на CTA.
  final Color ctaForeground;

  /// Обводка активной CTA (карточный border).
  final Color ctaBorder;

  /// Мягкий фон бейджей, иконок, секций.
  final Color soft;

  /// Акцент иконок и вторичных меток.
  final Color icon;
}

extension AppServiceAccentResolver on AppPalette {
  AppServiceAccent serviceAccent(AppServiceKind kind) {
    return switch (kind) {
      AppServiceKind.attendance => AppServiceAccent(
          cta: functionalSoftBlueIcon,
          ctaForeground: textInverse,
          ctaBorder: borderCardBlue,
          soft: functionalSoftBlue,
          icon: functionalSoftBlueIcon,
        ),
      AppServiceKind.booking => AppServiceAccent(
          cta: functionalSoftYellowIcon,
          ctaForeground: textInverse,
          ctaBorder: borderCardYellow,
          soft: functionalSoftYellow,
          icon: functionalSoftYellowIcon,
        ),
      AppServiceKind.bonus => AppServiceAccent(
          cta: functionalSoftOrangeIcon,
          ctaForeground: textInverse,
          ctaBorder: functionalSoftOrange,
          soft: functionalSoftOrange,
          icon: functionalSoftOrangeIcon,
        ),
    };
  }
}
