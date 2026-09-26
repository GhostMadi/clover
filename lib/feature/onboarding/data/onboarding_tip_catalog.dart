import 'package:clover/feature/onboarding/data/onboarding_catalog.dart';
import 'package:clover/feature/onboarding/data/onboarding_tip_id.dart';
import 'package:clover/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';

/// Где триггерим tip (хаб / первый open фичи).
abstract final class OnboardingSurface {
  static const bookingHub = 'booking_hub';
  static const attendanceHub = 'attendance_hub';
  static const resourcesHub = 'resources_hub';
  static const mapFirstOpen = 'map_first_open';
  static const bonusHub = 'bonus_hub';
}

/// Правило показа tip.
enum OnboardingTipGate {
  /// Разово при входе на [OnboardingTipDefinition.surface].
  onceOnSurface,

  /// Разово на surface **и** только если в профиле есть [OnboardingTipDefinition.requiredTag].
  onceOnSurfaceWithTag,
}

/// Описание умного tip (тексты на клиенте; id — EN ключ в кэше).
@immutable
class OnboardingTipDefinition {
  const OnboardingTipDefinition({
    required this.id,
    required this.serviceKey,
    required this.surface,
    required this.gate,
    required this.slidesFor,
    this.requiredTag,
    this.priority = 100,
  });

  final OnboardingTipId id;

  /// Домен: booking | attendance | resources | map | bonus | …
  final String serviceKey;

  /// См. [OnboardingSurface].
  final String surface;

  final OnboardingTipGate gate;

  /// Супер-тег EN (`booking`, `attendance`, `resources`) или null.
  final String? requiredTag;

  /// Меньше = раньше, если несколько unseen на одном surface.
  final int priority;

  final List<OnboardingSlideData> Function(AppLocalizations l10n) slidesFor;
}

/// Каталог service-tips. Новый сервис = новая запись + id в [OnboardingTipId].
abstract final class OnboardingTipCatalog {
  static final List<OnboardingTipDefinition> all = [
    OnboardingTipDefinition(
      id: OnboardingTipId.serviceBooking,
      serviceKey: 'booking',
      surface: OnboardingSurface.bookingHub,
      gate: OnboardingTipGate.onceOnSurfaceWithTag,
      requiredTag: 'booking',
      priority: 10,
      slidesFor: (l10n) => [
        OnboardingSlideData(
          emoji: '📅',
          title: l10n.onboarding_tip_booking_title,
          body: l10n.onboarding_tip_booking_body,
          tip: l10n.onboarding_tip_booking_tip,
          illustration: OnboardingIllustrationKind.services,
        ),
      ],
    ),
    OnboardingTipDefinition(
      id: OnboardingTipId.serviceAttendance,
      serviceKey: 'attendance',
      surface: OnboardingSurface.attendanceHub,
      gate: OnboardingTipGate.onceOnSurfaceWithTag,
      requiredTag: 'attendance',
      priority: 10,
      slidesFor: (l10n) => [
        OnboardingSlideData(
          emoji: '📍',
          title: l10n.onboarding_tip_attendance_title,
          body: l10n.onboarding_tip_attendance_body,
          tip: l10n.onboarding_tip_attendance_tip,
          illustration: OnboardingIllustrationKind.services,
        ),
      ],
    ),
    OnboardingTipDefinition(
      id: OnboardingTipId.serviceResources,
      serviceKey: 'resources',
      surface: OnboardingSurface.resourcesHub,
      gate: OnboardingTipGate.onceOnSurfaceWithTag,
      requiredTag: 'resources',
      priority: 10,
      slidesFor: (l10n) => [
        OnboardingSlideData(
          emoji: '📌',
          title: l10n.onboarding_tip_resources_title,
          body: l10n.onboarding_tip_resources_body,
          tip: l10n.onboarding_tip_resources_tip,
          illustration: OnboardingIllustrationKind.create,
        ),
      ],
    ),
    OnboardingTipDefinition(
      id: OnboardingTipId.serviceBonus,
      serviceKey: 'bonus',
      surface: OnboardingSurface.bonusHub,
      gate: OnboardingTipGate.onceOnSurface,
      priority: 20,
      slidesFor: (l10n) => [
        OnboardingSlideData(
          emoji: '🎁',
          title: l10n.onboarding_tip_bonus_title,
          body: l10n.onboarding_tip_bonus_body,
          tip: l10n.onboarding_tip_bonus_tip,
          illustration: OnboardingIllustrationKind.services,
        ),
      ],
    ),
    OnboardingTipDefinition(
      id: OnboardingTipId.tipMapEventsToggle,
      serviceKey: 'map',
      surface: OnboardingSurface.mapFirstOpen,
      gate: OnboardingTipGate.onceOnSurface,
      priority: 5,
      slidesFor: (l10n) => [
        OnboardingSlideData(
          emoji: '🗺️',
          title: l10n.onboarding_tip_feed_map_title,
          body: l10n.onboarding_tip_feed_map_body,
          tip: l10n.onboarding_tip_feed_map_tip,
          illustration: OnboardingIllustrationKind.feedMap,
        ),
      ],
    ),
  ];

  static List<OnboardingTipDefinition> forSurface(String surface) {
    final s = surface.trim();
    return [
      for (final tip in all)
        if (tip.surface == s) tip,
    ];
  }
}
