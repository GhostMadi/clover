import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:clover/core/config/mapbox.dart';
import 'package:clover/core/shared/app_map/app_map_cluster_icon_factory.dart';
import 'package:clover/core/shared/app_map/app_map_marker.dart';
import 'package:clover/core/shared/app_map/app_map_marker_icon_factory.dart';
import 'package:clover/core/shared/app_map/app_map_marker_tap.dart';
import 'package:clover/core/shared/app_map/app_map_point.dart';
import 'package:clover/core/shared/app_map/app_map_viewport.dart';
import 'package:clover/core/theme/app_color_binding.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

export 'app_map_marker.dart';
export 'app_map_marker_tap.dart';
export 'app_map_point.dart';
export 'app_map_viewport.dart';

/// Результат [AppMapController.moveToMyLocation].
enum AppMapMyLocationResult {
  /// Камера переехала на текущую позицию.
  moved,

  /// Нет разрешения на геолокацию.
  permissionDenied,

  /// Разрешение есть, но позицию пока не удалось получить.
  unavailable,
}

/// Управление [AppMap]: зум и переход к текущей геопозиции.
class AppMapController {
  _AppMapState? _state;

  bool get isReady => _state?._isReady ?? false;

  void _attach(_AppMapState state) => _state = state;

  void _detach(_AppMapState state) {
    if (_state == state) _state = null;
  }

  Future<void> zoomIn() => _state?.zoomIn() ?? SynchronousFuture(null);

  Future<void> zoomOut() => _state?.zoomOut() ?? SynchronousFuture(null);

  Future<void> moveTo(AppMapPoint point, {double? zoom}) =>
      _state?.moveTo(point, zoom: zoom) ?? SynchronousFuture(null);

  /// Переезд к текущей геопозиции. Точку вернёт только при [AppMapMyLocationResult.moved].
  Future<(AppMapMyLocationResult, AppMapPoint?)> moveToMyLocation() =>
      _state?.moveToMyLocation() ?? SynchronousFuture((AppMapMyLocationResult.unavailable, null));
}

/// Переиспользуемая карта на Mapbox.
class AppMap extends StatefulWidget {
  const AppMap({
    super.key,
    required this.initialCenter,
    this.selectedPoint,
    this.geofenceRadiusM,
    this.markers = const [],
    this.onPointSelected,
    this.onMarkerTap,
    this.onCameraChanged,
    this.controller,
  });

  final AppMapPoint initialCenter;
  final AppMapPoint? selectedPoint;

  /// Радиус геозоны в метрах вокруг [selectedPoint] (круг на карте).
  final double? geofenceRadiusM;

  final List<AppMapMarker> markers;
  final ValueChanged<AppMapPoint>? onPointSelected;
  final ValueChanged<AppMapMarkerTap>? onMarkerTap;
  final AppMapCameraChangedCallback? onCameraChanged;
  final AppMapController? controller;

  @override
  State<AppMap> createState() => _AppMapState();
}

class _AppMapState extends State<AppMap> {
  static const _defaultZoom = 14.0;
  static const _markerIconSize = 0.28;
  static final _animation = MapAnimationOptions(duration: 250);

  MapboxMap? _map;
  PointAnnotationManager? _pointManager;
  PolygonAnnotationManager? _polygonManager;
  Cancelable? _pointTapCancelable;
  Uint8List? _pinIconBytes;
  int _markersSyncGeneration = 0;
  Map<String, AppMapMarker> _markerById = const {};
  Map<String, List<AppMapMarker>> _stackByKey = const {};
  bool? _isDarkStyle;

  bool get _isReady => _map != null && _pointManager != null;

  @override
  void initState() {
    super.initState();
    widget.controller?._attach(this);
    unawaited(_loadPinIcon());
  }

  @override
  void dispose() {
    _pointTapCancelable?.cancel();
    widget.controller?._detach(this);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_isDarkStyle == isDark) return;
    final hadStyle = _isDarkStyle != null;
    _isDarkStyle = isDark;
    if (hadStyle && _map != null) {
      unawaited(_applyMapStyle(isDark));
    }
  }

  @override
  void didUpdateWidget(covariant AppMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._detach(this);
      widget.controller?._attach(this);
    }
    if (oldWidget.selectedPoint != widget.selectedPoint ||
        oldWidget.geofenceRadiusM != widget.geofenceRadiusM ||
        !_sameMarkers(oldWidget.markers, widget.markers)) {
      unawaited(_syncAnnotations());
    }
  }

  Future<void> moveTo(AppMapPoint point, {double? zoom}) => _moveTo(point, zoom: zoom);

  bool _sameMarkers(List<AppMapMarker> a, List<AppMapMarker> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      final left = a[i];
      final right = b[i];
      if (left.id != right.id ||
          left.emoji != right.emoji ||
          left.point != right.point ||
          left.borderColor != right.borderColor) {
        return false;
      }
    }
    return true;
  }

  Future<void> _loadPinIcon() async {
    final bytes = await _createPinImageBytes();
    if (!mounted) return;
    _pinIconBytes = bytes;
    await _syncAnnotations();
  }

  Point _toMapbox(AppMapPoint point) => Point(coordinates: Position(point.longitude, point.latitude));

  AppMapPoint _fromMapbox(Point point) {
    final c = point.coordinates;
    return AppMapPoint(latitude: c.lat.toDouble(), longitude: c.lng.toDouble());
  }

  Future<void> _moveTo(AppMapPoint point, {double? zoom}) async {
    final map = _map;
    if (map == null) return;
    await map.flyTo(
      CameraOptions(center: _toMapbox(point), zoom: zoom ?? _defaultZoom),
      _animation,
    );
  }

  Future<void> zoomIn() async {
    final map = _map;
    if (map == null) return;
    final state = await map.getCameraState();
    await map.flyTo(CameraOptions(zoom: state.zoom + 1), _animation);
  }

  Future<void> zoomOut() async {
    final map = _map;
    if (map == null) return;
    final state = await map.getCameraState();
    await map.flyTo(CameraOptions(zoom: state.zoom - 1), _animation);
  }

  Future<(AppMapMyLocationResult, AppMapPoint?)> moveToMyLocation() async {
    final map = _map;
    if (map == null) return (AppMapMyLocationResult.unavailable, null);

    final permission = await Permission.locationWhenInUse.request();
    if (!permission.isGranted) {
      return (AppMapMyLocationResult.permissionDenied, null);
    }

    await map.location.updateSettings(
      LocationComponentSettings(enabled: true, pulsingEnabled: true),
    );

    try {
      final position = await geo.Geolocator.getCurrentPosition(
        locationSettings: const geo.LocationSettings(
          accuracy: geo.LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );
      final point = AppMapPoint(latitude: position.latitude, longitude: position.longitude);
      await _moveTo(point, zoom: _defaultZoom);
      widget.onPointSelected?.call(point);
      return (AppMapMyLocationResult.moved, point);
    } on Object {
      return (AppMapMyLocationResult.unavailable, null);
    }
  }

  Future<void> _onMapCreated(MapboxMap map) async {
    _map = map;
    _isDarkStyle ??= Theme.of(context).brightness == Brightness.dark;
    await _hideMapChrome(map);
    await _applyLightPreset(map, isDark: _isDarkStyle!);
    await _setupAnnotationManagers(map);
    if (widget.onPointSelected != null) {
      map.addInteraction(
        TapInteraction.onMap((context) {
          widget.onPointSelected?.call(_fromMapbox(context.point));
        }),
      );
    }
    await _syncAnnotations();
  }

  Future<void> _setupAnnotationManagers(MapboxMap map) async {
    _pointTapCancelable?.cancel();
    _pointManager = await map.annotations.createPointAnnotationManager();
    _polygonManager = await map.annotations.createPolygonAnnotationManager();
    _pointTapCancelable = _pointManager!.tapEvents(onTap: _onPointAnnotationTap);
  }

  Future<void> _hideMapChrome(MapboxMap map) async {
    await Future.wait([
      map.logo.updateSettings(LogoSettings(enabled: false)),
      map.attribution.updateSettings(AttributionSettings(enabled: false)),
      map.compass.updateSettings(CompassSettings(enabled: false)),
      map.scaleBar.updateSettings(ScaleBarSettings(enabled: false)),
    ]);
  }

  Future<void> _applyLightPreset(MapboxMap map, {required bool isDark}) async {
    // Standard basemap: color theme всегда default; ночь = lightPreset night (огни домов).
    await map.style.setStyleImportConfigProperty('basemap', 'theme', 'default');
    await map.style.setStyleImportConfigProperty(
      'basemap',
      'lightPreset',
      isDark ? MapboxConfig.lightPresetNight : MapboxConfig.lightPresetDay,
    );
  }

  Future<void> _applyMapStyle(bool isDark) async {
    final map = _map;
    if (map == null) return;
    await _applyLightPreset(map, isDark: isDark);
  }

  void _onPointAnnotationTap(PointAnnotation annotation) {
    final data = annotation.customData;
    if (data == null || widget.onMarkerTap == null) return;
    final kind = data['kind'] as String?;
    if (kind == 'marker') {
      final id = data['id'] as String?;
      final marker = id == null ? null : _markerById[id];
      if (marker != null) {
        widget.onMarkerTap!(AppMapMarkerTap(marker: marker));
      }
      return;
    }
    if (kind == 'stack') {
      final key = data['key'] as String?;
      final group = key == null ? null : _stackByKey[key];
      if (group != null && group.isNotEmpty) {
        widget.onMarkerTap!(AppMapMarkerTap(marker: group.first, group: group));
      }
    }
  }

  Future<void> _syncAnnotations() async {
    final pointManager = _pointManager;
    final polygonManager = _polygonManager;
    if (pointManager == null || polygonManager == null) return;

    final generation = ++_markersSyncGeneration;
    final options = <PointAnnotationOptions>[];
    final selectedPoint = widget.selectedPoint;
    final geofenceRadius = widget.geofenceRadiusM;

    await polygonManager.deleteAll();
    if (selectedPoint != null && geofenceRadius != null && geofenceRadius > 0) {
      final p = AppColorBinding.palette;
      await polygonManager.create(
        PolygonAnnotationOptions(
          geometry: _geofencePolygon(selectedPoint, geofenceRadius),
          fillColor: p.functionalSoftBlue.withValues(alpha: 0.55).toARGB32(),
          fillOutlineColor: p.functionalSoftBlueIcon.toARGB32(),
          fillOpacity: 0.55,
        ),
      );
    }

    final pinBytes = _pinIconBytes;
    if (selectedPoint != null && pinBytes != null) {
      options.add(
        PointAnnotationOptions(
          geometry: _toMapbox(selectedPoint),
          image: pinBytes,
          iconSize: _markerIconSize,
          iconAnchor: IconAnchor.CENTER,
          customData: const {'kind': 'selected'},
        ),
      );
    }

    final markers = widget.markers;
    if (markers.isNotEmpty) {
      _markerById = {for (final marker in markers) marker.id: marker};
      final groups = _groupMarkersByLocation(markers);
      _stackByKey = {
        for (final entry in groups.entries)
          if (entry.value.length > 1) entry.key: entry.value,
      };

      final uniqueEmojis = markers.map((marker) => marker.emoji).toSet();
      final iconByEmoji = <String, Uint8List>{};
      final stackIconByKey = <String, Uint8List>{};

      await Future.wait(
        uniqueEmojis.map((emoji) async {
          iconByEmoji[emoji] = await AppMapMarkerIconFactory.bytesFor(emoji: emoji);
        }),
      );
      await Future.wait(
        groups.entries.where((entry) => entry.value.length > 1).map((entry) async {
          final emojis = [for (final marker in entry.value) marker.emoji];
          stackIconByKey[entry.key] = await AppMapClusterIconFactory.bytesFor(
            emojis: emojis,
            count: entry.value.length,
          );
        }),
      );

      if (!mounted || generation != _markersSyncGeneration) return;

      for (final entry in groups.entries) {
        if (entry.value.length == 1) {
          final marker = entry.value.first;
          options.add(
            PointAnnotationOptions(
              geometry: _toMapbox(marker.point),
              image: iconByEmoji[marker.emoji]!,
              iconSize: _markerIconSize,
              iconAnchor: IconAnchor.CENTER,
              customData: {'kind': 'marker', 'id': marker.id},
            ),
          );
        } else {
          options.add(
            PointAnnotationOptions(
              geometry: _toMapbox(entry.value.first.point),
              image: stackIconByKey[entry.key]!,
              iconSize: _markerIconSize,
              iconAnchor: IconAnchor.CENTER,
              customData: {'kind': 'stack', 'key': entry.key},
            ),
          );
        }
      }
    } else {
      _markerById = const {};
      _stackByKey = const {};
    }

    if (!mounted || generation != _markersSyncGeneration) return;
    await pointManager.deleteAll();
    if (options.isNotEmpty) {
      await pointManager.createMulti(options);
    }
  }

  Polygon _geofencePolygon(AppMapPoint center, double radiusM, {int steps = 64}) {
    final latRad = center.latitude * math.pi / 180;
    const metersPerDegLat = 111320.0;
    final metersPerDegLon = 111320.0 * math.cos(latRad);
    final ring = <Position>[];
    for (var i = 0; i <= steps; i++) {
      final a = (i / steps) * math.pi * 2;
      final dLat = (math.sin(a) * radiusM) / metersPerDegLat;
      final dLon = (math.cos(a) * radiusM) / metersPerDegLon;
      ring.add(Position(center.longitude + dLon, center.latitude + dLat));
    }
    return Polygon(coordinates: [ring]);
  }

  Map<String, List<AppMapMarker>> _groupMarkersByLocation(List<AppMapMarker> markers) {
    final groups = <String, List<AppMapMarker>>{};
    for (final marker in markers) {
      final key = _locationKey(marker.point);
      groups.putIfAbsent(key, () => []).add(marker);
    }
    return groups;
  }

  String _locationKey(AppMapPoint point) {
    return '${point.latitude.toStringAsFixed(6)}_${point.longitude.toStringAsFixed(6)}';
  }

  void _emitCamera({required bool finished}) {
    final map = _map;
    if (map == null || widget.onCameraChanged == null) return;
    unawaited(() async {
      final state = await map.getCameraState();
      final center = _fromMapbox(state.center);
      widget.onCameraChanged!(
        AppMapViewport(center: center, zoom: state.zoom),
        finished: finished,
      );
    }());
  }

  @override
  Widget build(BuildContext context) {
    return MapWidget(
      key: const ValueKey('app_map_mapbox'),
      styleUri: MapboxConfig.styleStandard,
      viewport: CameraViewportState(
        center: _toMapbox(widget.initialCenter),
        zoom: _defaultZoom,
      ),
      onMapCreated: _onMapCreated,
      onCameraChangeListener: widget.onCameraChanged == null ? null : (_) => _emitCamera(finished: false),
      onMapIdleListener: widget.onCameraChanged == null ? null : (_) => _emitCamera(finished: true),
    );
  }

  static Future<Uint8List> _createPinImageBytes() async {
    final p = AppColorBinding.palette;
    const size = 48.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final shadow = Paint()..color = p.shadowDark.withValues(alpha: 0.22);
    canvas.drawCircle(const Offset(size / 2, size / 2 + 1), 16, shadow);

    final fill = Paint()..color = p.primary;
    canvas.drawCircle(const Offset(size / 2, size / 2), 16, fill);

    final border = Paint()
      ..color = p.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(const Offset(size / 2, size / 2), 16, border);

    final image = await recorder.endRecording().toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return bytes!.buffer.asUint8List();
  }
}
