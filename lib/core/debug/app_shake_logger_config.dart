/// Shake → TalkerScreen для тестеров (TestFlight / внутренние сборки).
///
/// Перед публичным стором можно выставить [enabled] = false.
class AppShakeLoggerConfig {
  const AppShakeLoggerConfig._();

  /// Вкл. для тестеров во всех сборках (в т.ч. release).
  static const bool enabled = true;

  static const int maxEntries = 400;

  /// Полные req/res body в Supabase HTTP (иначе только одна строка →/←).
  static const bool logHttpBodies = false;

  /// Маршруты в Talker ([TalkerRouteObserver]).
  static const bool logNavigation = false;

  /// Порог ускорения (g ≈ м/с²); выше = реже срабатывает.
  static const double shakeThreshold = 18;

  /// Антидребезг между двумя открытиями.
  static const Duration shakeCooldown = Duration(seconds: 2);
}
