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
/// | [AppServiceKind.bonus] | розовый / красный |
/// | [AppServiceKind.venue] | coral `#FFA39E` (бронь / места) |
///
/// Чтобы сменить цвет сервиса — правь только [serviceAccent] и токены в [AppPalette].
enum AppServiceKind {
  /// Посещаемость — синий.
  attendance,

  /// Запись — жёлтый (`functionalSoftYellow` / `#FDF08B`).
  booking,

  /// Ресурсы — сиреневый soft + тёмный фиолет на CTA/иконках.
  resources,

  /// Бонусы — розовый soft + красный ink (как пара soft/icon у записи).
  bonus,

  /// Бронь / билеты / места — soft coral `#FFA39E`.
  venue,
}

/// Shortcut для территории «Ресурсы».
const AppServiceKind kResourcesService = AppServiceKind.resources;

/// Shortcut для территории «Бонусы».
const AppServiceKind kBonusService = AppServiceKind.bonus;

/// Цветовой набор сервиса: CTA, обводка кнопки, мягкий фон, иконки.
class AppServiceAccent {
  const AppServiceAccent({
    required this.cta,
    required this.ctaForeground,
    required this.ctaBorder,
    required this.soft,
    required this.icon,
    required this.onSoft,
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

  /// Текст на [soft] (читаемый и в dark: жёлтый soft остаётся светлым).
  final Color onSoft;
}

extension AppServiceAccentResolver on AppPalette {
  static const _inkOnLight = Color(0xFF1A1D1E);
  static const _inkOnDark = Color(0xFFFFFFFF);

  AppServiceAccent serviceAccent(AppServiceKind kind) {
    return switch (kind) {
      AppServiceKind.attendance => AppServiceAccent(
        cta: functionalSoftBlueIcon,
        ctaForeground: _inkOnDark,
        ctaBorder: borderCardBlue,
        soft: functionalSoftBlue,
        icon: functionalSoftBlueIcon,
        onSoft: _onSoftInk(functionalSoftBlue),
      ),
      AppServiceKind.booking => AppServiceAccent(
        cta: functionalSoftYellow,
        /// Жёлтый CTA всегда светлый — только тёмный текст (light и dark).
        ctaForeground: _inkOnLight,
        ctaBorder: borderCardYellow,
        soft: functionalSoftYellow,
        icon: functionalSoftYellowIcon,
        onSoft: _inkOnLight,
      ),
      AppServiceKind.resources => AppServiceAccent(
        cta: const Color(0xFF5C4FA8),
        ctaForeground: _inkOnDark,
        ctaBorder: borderCardLilac,
        soft: functionalSoftLilac,
        icon: functionalSoftLilacIcon,
        onSoft: _onSoftInk(functionalSoftLilac),
      ),
      AppServiceKind.bonus => AppServiceAccent(
        /// Как запись / venue: soft розовый остаётся светлым и в dark — тёмный текст читается.
        cta: const Color(0xFFFFC1D0),
        ctaForeground: _inkOnLight,
        ctaBorder: const Color(0xFFF5A8B8),
        soft: const Color(0xFFFFC1D0),
        icon: const Color(0xFFC2185B),
        onSoft: _inkOnLight,
      ),
      AppServiceKind.venue => AppServiceAccent(
        /// Soft coral CTA — всегда светлый, тёмный текст (как жёлтая запись).
        cta: functionalSoftVenue,
        ctaForeground: _inkOnLight,
        ctaBorder: borderCardVenue,
        soft: functionalSoftVenue,
        icon: functionalSoftVenueIcon,
        onSoft: _inkOnLight,
      ),
    };
  }

  Color _onSoftInk(Color soft) {
    return ThemeData.estimateBrightnessForColor(soft) == Brightness.dark
        ? _inkOnDark
        : _inkOnLight;
  }
}
