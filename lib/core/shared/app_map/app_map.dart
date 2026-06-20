import 'dart:ui' as ui;

import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/shared/app_map/app_map_point.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';

export 'app_map_point.dart';

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

  Future<void> moveToMyLocation() => _state?.moveToMyLocation() ?? SynchronousFuture(null);
}

/// Переиспользуемая карта на Yandex MapKit.
class AppMap extends StatefulWidget {
  const AppMap({
    super.key,
    required this.initialCenter,
    this.selectedPoint,
    this.onPointSelected,
    this.controller,
  });

  final AppMapPoint initialCenter;
  final AppMapPoint? selectedPoint;
  final ValueChanged<AppMapPoint>? onPointSelected;
  final AppMapController? controller;

  @override
  State<AppMap> createState() => _AppMapState();
}

class _AppMapState extends State<AppMap> {
  static const _placemarkId = MapObjectId('app_map_selected_point');
  static const _defaultZoom = 14.0;
  static const _animation = MapAnimation(type: MapAnimationType.smooth, duration: 0.25);

  YandexMapController? _controller;
  BitmapDescriptor? _pinIcon;
  List<MapObject> _mapObjects = [];

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
    if (oldWidget.selectedPoint != widget.selectedPoint) {
      _syncPlacemark();
    }
  }

  Future<void> _loadPinIcon() async {
    final bytes = await _createPinImageBytes();
    if (!mounted) return;
    setState(() {
      _pinIcon = BitmapDescriptor.fromBytes(bytes);
      _syncPlacemark();
    });
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

  Future<void> moveToMyLocation() async {
    final controller = _controller;
    if (controller == null) return;

    await controller.toggleUserLayer(visible: true, autoZoomEnabled: true);

    final position = await controller.getUserCameraPosition();
    if (position == null) return;

    await controller.moveCamera(CameraUpdate.newCameraPosition(position), animation: _animation);

    final point = _fromYandex(position.target);
    widget.onPointSelected?.call(point);
  }

  void _syncPlacemark() {
    final point = widget.selectedPoint;
    final icon = _pinIcon;

    if (point == null || icon == null) {
      setState(() => _mapObjects = const []);
      return;
    }

    setState(() {
      _mapObjects = [
        PlacemarkMapObject(
          mapId: _placemarkId,
          point: _toYandex(point),
          opacity: 1,
          icon: PlacemarkIcon.single(PlacemarkIconStyle(image: icon)),
        ),
      ];
    });
  }

  void _onMapTap(Point point) {
    widget.onPointSelected?.call(_fromYandex(point));
  }

  Future<void> _onMapCreated(YandexMapController controller) async {
    _controller = controller;
    await _moveTo(widget.initialCenter);
    _syncPlacemark();
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
