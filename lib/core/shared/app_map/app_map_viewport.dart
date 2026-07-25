import 'package:clover/core/shared/app_map/app_map_point.dart';

/// Видимая область карты: центр камеры и zoom.
class AppMapViewport {
  const AppMapViewport({required this.center, required this.zoom});

  final AppMapPoint center;
  final double zoom;
}

typedef AppMapCameraChangedCallback = void Function(AppMapViewport viewport, {required bool finished});
