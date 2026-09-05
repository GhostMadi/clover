import 'package:clover/core/shared/app_map/app_map_marker.dart';
import 'package:clover/core/shared/app_map/app_map_viewport.dart';
import 'package:clover/feature/_feed_/events_page/data/models/events_filter.dart';
import 'package:clover/feature/_feed_/map_page/data/map_viewport_query.dart';
import 'package:clover/feature/_feed_/map_page/data/models/map_marker_item.dart';
import 'package:clover/feature/_feed_/map_page/data/repository/map_markers_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

/// Маркеры в viewport — без пагинации (как 2ГИС: всё видимое, кластеры на карте).
@injectable
class MapMarkersCubit extends Cubit<MapMarkersState> {
  MapMarkersCubit(this._repository) : super(const MapMarkersState.initial());

  final MapMarkersRepository _repository;

  int _loadGeneration = 0;
  AppMapViewport? _lastFetchedViewport;
  EventsFilter? _filter;

  Future<void> load({
    required AppMapViewport viewport,
    required EventsFilter filter,
    bool force = false,
  }) async {
    _filter = filter;

    if (!force &&
        _lastFetchedViewport != null &&
        !MapViewportQuery.shouldFetch(previous: _lastFetchedViewport!, next: viewport)) {
      return;
    }

    await _fetchViewport(viewport);
  }

  /// Камера остановилась — подгрузить маркеры, если ушли достаточно далеко / изменили zoom.
  Future<void> onViewportSettled(AppMapViewport viewport) async {
    final filter = _filter;
    if (filter == null) return;
    await load(viewport: viewport, filter: filter);
  }

  Future<void> _fetchViewport(AppMapViewport viewport) async {
    final filter = _filter;
    if (filter == null) return;

    final generation = ++_loadGeneration;
    final previousMarkers = state.mapMarkers;

    emit(
      state.copyWith(
        isLoading: true,
        errorMessage: null,
        mapMarkers: previousMarkers,
      ),
    );

    try {
      final page = await _repository.fetchPage(
        center: viewport.center,
        zoom: viewport.zoom,
        filter: filter,
        offset: 0,
        limit: MapViewportQuery.limit(viewport.zoom),
      );

      if (isClosed || generation != _loadGeneration) return;

      _lastFetchedViewport = viewport;

      emit(
        MapMarkersState.loaded(
          markers: page.items,
          mapMarkers: [
            for (final item in page.items)
              AppMapMarker(
                id: item.id,
                point: item.point,
                emoji: item.textEmoji,
              ),
          ],
        ),
      );
    } catch (error) {
      if (isClosed || generation != _loadGeneration) return;
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: error.toString(),
          mapMarkers: previousMarkers,
        ),
      );
    }
  }
}

class MapMarkersState {
  const MapMarkersState._({
    required this.isLoading,
    this.markers = const [],
    this.mapMarkers = const [],
    this.errorMessage,
  });

  const MapMarkersState.initial() : this._(isLoading: false);

  const MapMarkersState.loaded({
    required List<MapMarkerItem> markers,
    required List<AppMapMarker> mapMarkers,
  }) : this._(
          isLoading: false,
          markers: markers,
          mapMarkers: mapMarkers,
        );

  final bool isLoading;
  final List<MapMarkerItem> markers;
  final List<AppMapMarker> mapMarkers;
  final String? errorMessage;

  MapMarkersState copyWith({
    bool? isLoading,
    List<MapMarkerItem>? markers,
    List<AppMapMarker>? mapMarkers,
    String? errorMessage,
  }) {
    return MapMarkersState._(
      isLoading: isLoading ?? this.isLoading,
      markers: markers ?? this.markers,
      mapMarkers: mapMarkers ?? this.mapMarkers,
      errorMessage: errorMessage,
    );
  }
}
