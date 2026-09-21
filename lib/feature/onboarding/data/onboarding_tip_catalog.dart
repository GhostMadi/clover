import 'package:clover/feature/onboarding/data/onboarding_catalog.dart';
import 'package:clover/feature/onboarding/data/onboarding_tip_id.dart';
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
    required this.slides,
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

  final List<OnboardingSlideData> slides;
}

/// Каталог service-tips. Новый сервис = новая запись + id в [OnboardingTipId].
abstract final class OnboardingTipCatalog {
  static const List<OnboardingTipDefinition> all = [
    OnboardingTipDefinition(
      id: OnboardingTipId.serviceBooking,
      serviceKey: 'booking',
      surface: OnboardingSurface.bookingHub,
      gate: OnboardingTipGate.onceOnSurfaceWithTag,
      requiredTag: 'booking',
      priority: 10,
      slides: [
        OnboardingSlideData(
          emoji: '📅',
          title: 'Онлайн-запись',
          body: 'Услуги, мастера, inbox и клиент с вашего профиля — в одном сервисе.',
          tip: 'Супер-тег «Принимаю запись» включает хаб.',
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
      slides: [
        OnboardingSlideData(
          emoji: '📍',
          title: 'Посещаемость',
          body: 'Компании, смены и отметки команды. Работник отмечает в приложении.',
          tip: 'Супер-тег «Посещаемость» открывает управление.',
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
      slides: [
        OnboardingSlideData(
          emoji: '📌',
          title: 'Ресурсы',
          body: 'Ваши места для постов и фильтры витрины профиля — личный справочник.',
          tip: 'Не путать с городом ленты.',
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
      slides: [
        OnboardingSlideData(
          emoji: '🎁',
          title: 'Бонусы',
          body: 'Копите и тратьте там, где хозяин включил бонусы на услуге.',
          tip: 'Подробности — в гайде сервисов.',
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
      slides: [
        OnboardingSlideData(
          emoji: '🗺️',
          title: 'Лента и карта',
          body: 'Двойной тап по Home — переключение ленты и карты города.',
          tip: 'Фильтры слева, уведомления справа.',
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
