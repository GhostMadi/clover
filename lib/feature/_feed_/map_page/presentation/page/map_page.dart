import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/shared/app_functional_button/app_functional_pill_button.dart';
import 'package:clover/core/shared/app_map/app_map.dart';
import 'package:clover/core/shared/app_nav_bar/app_nav_bar.dart';
import 'package:clover/core/shared/app_snack_bar.dart';
import 'package:clover/feature/_feed_/events_page/data/models/events_filter.dart';
import 'package:clover/feature/_feed_/map_page/data/models/map_marker_item.dart';
import 'package:clover/feature/_feed_/map_page/presentation/cubit/map_markers_cubit.dart';
import 'package:clover/feature/_feed_/map_page/presentation/scope/map_markers_filter_scope.dart';
import 'package:clover/feature/_feed_/map_page/presentation/widget/map_marker_group_sheet.dart';
import 'package:clover/feature/_feed_/map_page/presentation/widget/map_marker_post_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

@RoutePage()
class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  static const _defaultCenter = AppMapPoint(latitude: 43.238949, longitude: 76.889709);
  static const _defaultZoom = 14.0;

  late final MapMarkersCubit _markersCubit;
  final AppMapController _mapController = AppMapController();

  AppMapViewport _viewport = const AppMapViewport(center: _defaultCenter, zoom: _defaultZoom);
  EventsFilter? _lastFilter;

  @override
  void initState() {
    super.initState();
    _markersCubit = sl<MapMarkersCubit>();
  }

  @override
  void dispose() {
    _markersCubit.close();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final filter = MapMarkersFilterScope.of(context);
    if (_lastFilter != filter) {
      _lastFilter = filter;
      _reloadMarkers(force: true);
    }
  }

  void _reloadMarkers({bool force = false}) {
    final filter = _lastFilter ?? MapMarkersFilterScope.of(context);
    unawaited(_markersCubit.load(viewport: _viewport, filter: filter, force: force));
  }

  void _onCameraChanged(AppMapViewport viewport, {required bool finished}) {
    _viewport = viewport;
    if (finished) {
      unawaited(_markersCubit.onViewportSettled(viewport));
    }
  }

  Future<void> _moveToMyLocation() async {
    final point = await _mapController.moveToMyLocation();
    if (!mounted || point == null) return;

    _viewport = AppMapViewport(center: point, zoom: _viewport.zoom);
    _reloadMarkers(force: true);
  }

  Map<String, MapMarkerItem> _markersById(MapMarkersState state) {
    return {for (final marker in state.markers) marker.id: marker};
  }

  Future<void> _openPostForMarker(MapMarkerItem marker) async {
    final postId = marker.postId?.trim();
    if (postId == null || postId.isEmpty) {
      AppSnackBar.show(context, message: 'У маркера нет поста', kind: AppSnackBarKind.info);
      return;
    }

    await MapMarkerPostSheet.show(context, postId: postId);
  }

  Future<void> _onMarkerTap(AppMapMarkerTap tap, MapMarkersState state) async {
    final byId = _markersById(state);

    if (tap.isGroup) {
      final groupItems = [
        for (final marker in tap.group!)
          if (byId.containsKey(marker.id)) byId[marker.id]!,
      ];
      if (groupItems.isEmpty) return;

      final picked = await MapMarkerGroupSheet.show(context, markers: groupItems);
      if (!mounted || picked == null) return;
      await _openPostForMarker(picked);
      return;
    }

    final item = byId[tap.marker.id];
    if (item == null) return;
    await _openPostForMarker(item);
  }

  @override
  Widget build(BuildContext context) {
    final controlsBottom = AppNavBar.scrollBottomClearance(context);
    final locationBottom = controlsBottom + 16;

    return BlocProvider.value(
      value: _markersCubit,
      child: BlocBuilder<MapMarkersCubit, MapMarkersState>(
        builder: (context, state) {
          return Scaffold(
            backgroundColor: context.colors.pageBackground,
            body: Stack(
              fit: StackFit.expand,
              children: [
                AppMap(
                  controller: _mapController,
                  initialCenter: _viewport.center,
                  markers: state.mapMarkers,
                  onCameraChanged: _onCameraChanged,
                  onMarkerTap: (tap) => unawaited(_onMarkerTap(tap, state)),
                ),
                Positioned(
                  right: 16,
                  bottom: locationBottom,
                  child: AppFunctionalPillButton(
                    icon: AppIcons.myLocation.icon,
                    customColor: context.colors.functionalSoftBlue,
                    iconColor: context.colors.functionalSoftBlueIcon,
                    backgroundColor: context.colors.white,
                    borderColor: context.colors.primary,
                    onTap: () => unawaited(_moveToMyLocation()),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
