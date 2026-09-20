/// Идентификаторы онбордингов / service-tips.
///
/// [appV2] — стартовый флоу с выбором сюжета (гость / бизнес / оба).
/// [appV1] — старый mono-flow (история; новые пользователи идут на v2).
/// Остальные — будущие разовые показы новых сервисов.
enum OnboardingTipId {
  appV1('app_v1'),
  appV2('app_v2'),
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
