/// Публичный токен Mapbox для Flutter (`clover_flutter`).
///
/// Не хранить `pk.` / `sk.` в git. Локально и в CI:
/// `--dart-define=MAPBOX_ACCESS_TOKEN=pk.…`
///
/// Secret с `DOWNLOADS:READ` — только в `~/.netrc` и `SDK_REGISTRY_TOKEN`
/// (android/gradle.properties локально / GitHub Secrets).
class MapboxConfig {
  const MapboxConfig._();

  static const accessToken = String.fromEnvironment('MAPBOX_ACCESS_TOKEN');

  /// Всегда Standard; свет/ночь — через `lightPreset` (day / night).
  static const styleStandard = 'mapbox://styles/mapbox/standard';

  static const lightPresetDay = 'day';
  static const lightPresetNight = 'night';
}
