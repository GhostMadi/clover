/// Shake → TalkerScreen для тестеров (TestFlight / внутренние сборки).
///
/// Перед публичным стором можно выставить [enabled] = false.
class AppShakeLoggerConfig {
  const AppShakeLoggerConfig._();

  /// Вкл. для тестеров во всех сборках (в т.ч. release).
  static const bool enabled = true;

  static const int maxEntries = 800;

  /// Порог ускорения (g ≈ м/с²); выше = реже срабатывает.
  static const double shakeThreshold = 18;

  /// Антидребезг между двумя открытиями.
  static const Duration shakeCooldown = Duration(seconds: 2);
}
