import 'package:clover/core/theme/app_palette.dart';
import 'package:flutter/material.dart';

/// Продуктовый сервис с собственным визуальным акцентом (CTA, иконки, мягкие фоны).
///
/// Бренд приложения ([AppPalette.primary]) — зелёный Clover.
/// На территории сервиса зелёный **уступает** цвету сервиса: «Назад», чипы,
/// поля, CTA — через [AppServiceAccent] / `service:` у shared-контролов.
///
/// | Сервис | Цвет |
/// |--------|------|
/// | [AppServiceKind.attendance] | синий |
/// | [AppServiceKind.booking] | жёлтый `#FDF08B` |
/// | [AppServiceKind.resources] | сиреневый / фиолет |
/// | [AppServiceKind.bonus] | оранжевый |
///
/// Чтобы сменить цвет сервиса — правь только [serviceAccent] и токены в [AppPalette].
enum AppServiceKind {
  /// Посещаемость — синий.
  attendance,

  /// Запись — жёлтый (`functionalSoftYellow` / `#FDF08B`).
  booking,

  /// Ресурсы — сиреневый soft + тёмный фиолет на CTA/иконках.
  resources,

  /// Бонусы — оранжевый.
  bonus,
}

/// Shortcut для территории «Ресурсы».
const AppServiceKind kResourcesService = AppServiceKind.resources;

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
        cta: functionalSoftYellow,

        /// Всегда тёмный текст на жёлтом (и в dark theme).
        ctaForeground: const Color(0xFF1A1D1E),
        ctaBorder: borderCardYellow,
        soft: functionalSoftYellow,
        icon: functionalSoftYellowIcon,
      ),
      AppServiceKind.resources => AppServiceAccent(
        /// Тёмный фиолет как заливка CTA — на нём белый читается (и в dark).
        cta: const Color(0xFF5C4FA8),
        ctaForeground: const Color(0xFFFFFFFF),
        ctaBorder: borderCardLilac,
        soft: functionalSoftLilac,
        icon: functionalSoftLilacIcon,
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
