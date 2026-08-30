import 'dart:math' as math;

import 'package:clover/core/shared/app_map/app_map_point.dart';
import 'package:clover/core/shared/app_map/app_map_viewport.dart';

/// Параметры запроса маркеров по zoom (радиус, лимит, порог перезагрузки).
abstract final class MapViewportQuery {
  static const _refZoom = 12.0;
  static const _refRadiusM = 28000.0;
  static const _earthRadiusM = 6371000.0;

  /// Доля радиуса запроса: сдвиг меньше — не дергаем Supabase повторно.
  static const reloadCenterFraction = 0.4;

  static const reloadZoomDelta = 0.45;

  static double radiusM(double zoom) {
    final scale = math.pow(2, _refZoom - zoom).toDouble();
    return (_refRadiusM * scale).clamp(2500, 120000);
  }

  static int limit(double zoom) {
    if (zoom >= 16) return 200;
    if (zoom >= 14) return 300;
    if (zoom >= 12) return 400;
    return 500;
  }

  /// Нужен ли новый запрос относительно последнего успешного viewport.
  static bool shouldFetch({
    required AppMapViewport previous,
    required AppMapViewport next,
  }) {
    if ((next.zoom - previous.zoom).abs() >= reloadZoomDelta) return true;

    final movedM = distanceM(previous.center, next.center);
    final thresholdM = radiusM(next.zoom) * reloadCenterFraction;
    return movedM >= thresholdM;
  }

  static double distanceM(AppMapPoint a, AppMapPoint b) {
    final dLat = _toRad(b.latitude - a.latitude);
    final dLng = _toRad(b.longitude - a.longitude);
    final lat1 = _toRad(a.latitude);
    final lat2 = _toRad(b.latitude);

    final h =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) * math.cos(lat2) * math.sin(dLng / 2) * math.sin(dLng / 2);

    return _earthRadiusM * 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
  }

  static double _toRad(double deg) => deg * math.pi / 180;
}
