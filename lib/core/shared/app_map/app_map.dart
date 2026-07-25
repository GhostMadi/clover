import 'dart:async';
import 'dart:ui' as ui;

import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/shared/app_map/app_map_cluster_icon_factory.dart';
import 'package:clover/core/shared/app_map/app_map_marker.dart';
import 'package:clover/core/shared/app_map/app_map_marker_tap.dart';
import 'package:clover/core/shared/app_map/app_map_marker_icon_factory.dart';
import 'package:clover/core/shared/app_map/app_map_point.dart';
import 'package:clover/core/shared/app_map/app_map_viewport.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';

export 'app_map_marker.dart';
export 'app_map_marker_tap.dart';
export 'app_map_point.dart';
export 'app_map_viewport.dart';

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

  Future<AppMapPoint?> moveToMyLocation() => _state?.moveToMyLocation() ?? SynchronousFuture(null);
}

/// Переиспользуемая карта на Yandex MapKit.
class AppMap extends StatefulWidget {
  const AppMap({
    super.key,
    required this.initialCenter,
    this.selectedPoint,
    this.markers = const [],
    this.onPointSelected,
    this.onMarkerTap,
    this.onCameraChanged,
    this.controller,
  });

  final AppMapPoint initialCenter;
  final AppMapPoint? selectedPoint;
  final List<AppMapMarker> markers;
  final ValueChanged<AppMapPoint>? onPointSelected;
  final ValueChanged<AppMapMarkerTap>? onMarkerTap;
  final AppMapCameraChangedCallback? onCameraChanged;
  final AppMapController? controller;

  @override
  State<AppMap> createState() => _AppMapState();
}

class _AppMapState extends State<AppMap> {
  static const _selectedPlacemarkId = MapObjectId('app_map_selected_point');
  static const _markersClusterId = MapObjectId('app_map_markers_cluster');
  static const _defaultZoom = 14.0;
  static const _animation = MapAnimation(type: MapAnimationType.smooth, duration: 0.25);

  YandexMapController? _controller;
  BitmapDescriptor? _pinIcon;
  List<MapObject> _mapObjects = [];
  int _markersSyncGeneration = 0;
  Map<String, String> _emojiByMarkerId = const {};
  Map<String, List<String>> _emojisByPlacemarkId = const {};

  bool get _isReady => _controller != null;

  @override
  void initState() {
    super.initState();
    widget.controller?._attach(this);
    _loadPinIcon();
  }

  @override
  void dispose() {
    widget.controller?._detach(this);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant AppMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._detach(this);
      widget.controller?._attach(this);
    }
    if (oldWidget.selectedPoint != widget.selectedPoint || !_sameMarkers(oldWidget.markers, widget.markers)) {
      unawaited(_syncMapObjects());
    }
  }

  bool _sameMarkers(List<AppMapMarker> a, List<AppMapMarker> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      final left = a[i];
      final right = b[i];
      if (left.id != right.id || left.emoji != right.emoji || left.point != right.point) {
        return false;
      }
    }
    return true;
  }

  Future<void> _loadPinIcon() async {
    final bytes = await _createPinImageBytes();
    if (!mounted) return;
    setState(() {
      _pinIcon = BitmapDescriptor.fromBytes(bytes);
    });
    await _syncMapObjects();
  }

  Point _toYandex(AppMapPoint point) => Point(latitude: point.latitude, longitude: point.longitude);

  AppMapPoint _fromYandex(Point point) => AppMapPoint(latitude: point.latitude, longitude: point.longitude);

  Future<void> _moveTo(AppMapPoint point, {double? zoom}) async {
    final controller = _controller;
    if (controller == null) return;

    await controller.moveCamera(
      CameraUpdate.newCameraPosition(CameraPosition(target: _toYandex(point), zoom: zoom ?? _defaultZoom)),
      animation: _animation,
    );
  }

  Future<void> zoomIn() async {
    final controller = _controller;
    if (controller == null) return;
    await controller.moveCamera(CameraUpdate.zoomIn(), animation: _animation);
  }

  Future<void> zoomOut() async {
    final controller = _controller;
    if (controller == null) return;
    await controller.moveCamera(CameraUpdate.zoomOut(), animation: _animation);
  }

  Future<AppMapPoint?> moveToMyLocation() async {
    final controller = _controller;
    if (controller == null) return null;

    await controller.toggleUserLayer(visible: true, autoZoomEnabled: true);

    final position = await controller.getUserCameraPosition();
    if (position == null) return null;

    await controller.moveCamera(CameraUpdate.newCameraPosition(position), animation: _animation);

    final point = _fromYandex(position.target);
    widget.onPointSelected?.call(point);
    return point;
  }

  Future<void> _syncMapObjects() async {
    final generation = ++_markersSyncGeneration;
    final objects = <MapObject>[];

    final selectedPoint = widget.selectedPoint;
    final pinIcon = _pinIcon;
    if (selectedPoint != null && pinIcon != null) {
      objects.add(
        PlacemarkMapObject(
          mapId: _selectedPlacemarkId,
          point: _toYandex(selectedPoint),
          opacity: 1,
          icon: PlacemarkIcon.single(PlacemarkIconStyle(image: pinIcon)),
        ),
      );
    }

    final markers = widget.markers;
    if (markers.isNotEmpty) {
      _emojiByMarkerId = {for (final marker in markers) marker.id: marker.emoji};
      final emojisByPlacemarkId = <String, List<String>>{};

      final uniqueEmojis = markers.map((marker) => marker.emoji).toSet();
      final iconByEmoji = <String, BitmapDescriptor>{};
      final stackIconByKey = <String, BitmapDescriptor>{};

      await Future.wait(
        uniqueEmojis.map((emoji) async {
          final bytes = await AppMapMarkerIconFactory.bytesFor(emoji: emoji);
          iconByEmoji[emoji] = BitmapDescriptor.fromBytes(bytes);
        }),
      );

      final groups = _groupMarkersByLocation(markers);
      await Future.wait(
        groups.entries.where((entry) => entry.value.length > 1).map((entry) async {
          final emojis = [for (final marker in entry.value) marker.emoji];
          final bytes = await AppMapClusterIconFactory.bytesFor(emojis: emojis, count: entry.value.length);
          stackIconByKey[entry.key] = BitmapDescriptor.fromBytes(bytes);
        }),
      );

      if (!mounted || generation != _markersSyncGeneration) return;

      final placemarks = <PlacemarkMapObject>[];
      for (final entry in groups.entries) {
        if (entry.value.length == 1) {
          final marker = entry.value.first;
          emojisByPlacemarkId['marker_${marker.id}'] = [marker.emoji];
          placemarks.add(_placemarkForMarker(marker, iconByEmoji[marker.emoji]!));
        } else {
          final stackEmojis = [for (final marker in entry.value) marker.emoji];
          emojisByPlacemarkId['marker_stack_${entry.key}'] = stackEmojis;
          placemarks.add(_placemarkForStack(entry.key, entry.value, stackIconByKey[entry.key]!));
        }
      }

      _emojisByPlacemarkId = emojisByPlacemarkId;

      objects.add(
        ClusterizedPlacemarkCollection(
          mapId: _markersClusterId,
          placemarks: placemarks,
          radius: 56,
          minZoom: 15,
          onClusterAdded: _onClusterAdded,
        ),
      );
    }

    if (!mounted || generation != _markersSyncGeneration) return;
    setState(() => _mapObjects = objects);
  }

  Future<Cluster?> _onClusterAdded(ClusterizedPlacemarkCollection self, Cluster cluster) async {
    final emojis = <String>[];
    for (final placemark in cluster.placemarks) {
      final mapped = _emojisByPlacemarkId[placemark.mapId.value];
      if (mapped != null) {
        emojis.addAll(mapped);
        continue;
      }

      final emoji = _emojiByMarkerId[_markerIdFromMapId(placemark.mapId)];
      if (emoji != null) emojis.add(emoji);
    }

    final bytes = await AppMapClusterIconFactory.bytesFor(emojis: emojis, count: cluster.size);
    return cluster.copyWith(
      appearance: cluster.appearance.copyWith(
        icon: PlacemarkIcon.single(
          PlacemarkIconStyle(
            image: BitmapDescriptor.fromBytes(bytes),
            anchor: AppMapClusterIconFactory.anchor,
          ),
        ),
      ),
    );
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

  String _markerIdFromMapId(MapObjectId mapId) {
    final value = mapId.value;
    if (value.startsWith('marker_stack_')) return value.substring('marker_stack_'.length);
    if (value.startsWith('marker_')) return value.substring('marker_'.length);
    return value;
  }

  PlacemarkMapObject _placemarkForMarker(AppMapMarker marker, BitmapDescriptor icon) {
    return PlacemarkMapObject(
      mapId: MapObjectId('marker_${marker.id}'),
      point: _toYandex(marker.point),
      opacity: 1,
      consumeTapEvents: true,
      onTap: widget.onMarkerTap == null
          ? null
          : (_, __) => widget.onMarkerTap!(AppMapMarkerTap(marker: marker)),
      icon: PlacemarkIcon.single(
        PlacemarkIconStyle(
          image: icon,
          scale: AppMapMarkerIconFactory.mapScale,
          anchor: const Offset(0.5, 0.5),
        ),
      ),
    );
  }

  PlacemarkMapObject _placemarkForStack(String locationKey, List<AppMapMarker> markers, BitmapDescriptor icon) {
    final point = markers.first.point;
    final primary = markers.first;

    return PlacemarkMapObject(
      mapId: MapObjectId('marker_stack_$locationKey'),
      point: _toYandex(point),
      opacity: 1,
      consumeTapEvents: true,
      onTap: widget.onMarkerTap == null
          ? null
          : (_, __) => widget.onMarkerTap!(AppMapMarkerTap(marker: primary, group: markers)),
      icon: PlacemarkIcon.single(
        PlacemarkIconStyle(
          image: icon,
          scale: AppMapMarkerIconFactory.mapScale,
          anchor: AppMapClusterIconFactory.anchor,
        ),
      ),
    );
  }

  void _onMapTap(Point point) {
    widget.onPointSelected?.call(_fromYandex(point));
  }

  void _onCameraPositionChanged(CameraPosition position, CameraUpdateReason reason, bool finished) {
    widget.onCameraChanged?.call(
      AppMapViewport(center: _fromYandex(position.target), zoom: position.zoom),
      finished: finished,
    );
  }

  Future<void> _onMapCreated(YandexMapController controller) async {
    _controller = controller;
    await _moveTo(widget.initialCenter);
    await _syncMapObjects();
  }

  @override
  Widget build(BuildContext context) {
    return YandexMap(
      mapType: MapType.map,
      rotateGesturesEnabled: true,
      tiltGesturesEnabled: false,
      scrollGesturesEnabled: true,
      zoomGesturesEnabled: true,
      fastTapEnabled: true,
      onMapCreated: _onMapCreated,
      onMapTap: widget.onPointSelected == null ? null : _onMapTap,
      onCameraPositionChanged: widget.onCameraChanged == null ? null : _onCameraPositionChanged,
      mapObjects: _mapObjects,
    );
  }

  static Future<Uint8List> _createPinImageBytes() async {
    const size = 48.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final shadow = Paint()..color = AppColors.shadowDark.withValues(alpha: 0.22);
    canvas.drawCircle(const Offset(size / 2, size / 2 + 1), 16, shadow);

    final fill = Paint()..color = AppColors.primary;
    canvas.drawCircle(const Offset(size / 2, size / 2), 16, fill);

    final border = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(const Offset(size / 2, size / 2), 16, border);

    final image = await recorder.endRecording().toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return bytes!.buffer.asUint8List();
  }
}
