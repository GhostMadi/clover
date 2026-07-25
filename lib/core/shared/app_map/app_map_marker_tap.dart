import 'package:clover/core/shared/app_map/app_map_marker.dart';

/// Тап по маркеру на карте.
class AppMapMarkerTap {
  const AppMapMarkerTap({required this.marker, this.group});

  final AppMapMarker marker;

  /// Несколько маркеров в одной точке; `null` или длина 1 — одиночный маркер.
  final List<AppMapMarker>? group;

  bool get isGroup => group != null && group!.length > 1;
}
