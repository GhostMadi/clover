/// Идентификаторы онбордингов / service-tips.
///
/// [appV1] — стартовый флоу после первого входа.
/// Остальные — будущие разовые показы новых сервисов (без повторного app-onboarding).
enum OnboardingTipId {
  appV1('app_v1'),
  serviceBooking('service_booking'),
  serviceBonus('service_bonus'),
  tipMapEventsToggle('tip_map_events_toggle');

  const OnboardingTipId(this.storageValue);

  final String storageValue;

  static OnboardingTipId? tryParse(String raw) {
    for (final id in values) {
      if (id.storageValue == raw) return id;
    }
    return null;
  }
}
