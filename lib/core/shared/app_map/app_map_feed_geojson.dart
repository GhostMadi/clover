import 'package:clover/core/shared/app_map/app_map_marker.dart';
import 'package:clover/core/shared/app_map/app_map_point.dart';

/// Группировка маркеров по координате (стопки на одной точке).
///
/// Серверные кластеры и точки рисуются PNG-аннотациями в [AppMap], не GeoJSON.
abstract final class AppMapFeedGeoJson {
  static String locationKey(AppMapPoint point) =>
      '${point.latitude.toStringAsFixed(6)}_${point.longitude.toStringAsFixed(6)}';

  static Map<String, List<AppMapMarker>> groupByLocation(List<AppMapMarker> markers) {
    final groups = <String, List<AppMapMarker>>{};
    for (final marker in markers) {
      groups.putIfAbsent(locationKey(marker.point), () => []).add(marker);
    }
    return groups;
  }
}
