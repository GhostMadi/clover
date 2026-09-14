import 'dart:async';

import 'package:clover/core/shared/app_map/app_map_marker.dart';
import 'package:clover/core/shared/app_map/app_map_viewport.dart';
import 'package:clover/feature/_feed_/events_page/data/models/events_filter.dart';
import 'package:clover/feature/_feed_/map_page/data/map_markers_local_cache.dart';
import 'package:clover/feature/_feed_/map_page/data/map_viewport_query.dart';
import 'package:clover/feature/_feed_/map_page/data/models/map_marker_item.dart';
import 'package:clover/feature/_feed_/map_page/data/repository/map_markers_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

/// Маркеры в viewport: disk cache → RPC (stale-while-revalidate).
///
/// Не спамит `list_markers_map`: debounce idle, один in-flight, порог сдвига,
/// после ошибки viewport считается «уже пробовали» (иначе Mapbox idle → шторм).
@injectable
class MapMarkersCubit extends Cubit<MapMarkersState> {
  MapMarkersCubit(this._repository, this._localCache) : super(const MapMarkersState.initial());

  final MapMarkersRepository _repository;
  final MapMarkersLocalCache _localCache;

  static const _settleDebounce = Duration(milliseconds: 450);
  static const _errorCooldown = Duration(seconds: 8);

  int _loadGeneration = 0;
  AppMapViewport? _lastFetchedViewport;
  AppMapViewport? _lastAttemptViewport;
  DateTime? _lastErrorAt;
  EventsFilter? _filter;
  bool _inFlight = false;
  Timer? _settleTimer;

  Future<void> load({
    required AppMapViewport viewport,
    required EventsFilter filter,
    bool force = false,
  }) async {
    _filter = filter;

    if (!force && !_shouldStartFetch(viewport)) return;
    if (_inFlight && !force) return;

    await _fetchViewport(viewport);
  }

  /// Камера остановилась — подгрузить, если ушли достаточно далеко / zoom.
  void onViewportSettled(AppMapViewport viewport) {
    final filter = _filter;
    if (filter == null) return;

    _settleTimer?.cancel();
    _settleTimer = Timer(_settleDebounce, () {
      unawaited(load(viewport: viewport, filter: filter));
    });
  }

  bool _shouldStartFetch(AppMapViewport viewport) {
    final baseline = _lastFetchedViewport ?? _lastAttemptViewport;
    if (baseline != null &&
        !MapViewportQuery.shouldFetch(previous: baseline, next: viewport)) {
      final erred = _lastErrorAt;
      if (erred == null) return false;
      // Тот же viewport после ошибки — не долбить, пока не пройдёт cooldown.
      if (DateTime.now().difference(erred) < _errorCooldown) return false;
    }
    return true;
  }

  Future<void> _fetchViewport(AppMapViewport viewport) async {
    final filter = _filter;
    if (filter == null) return;

    final generation = ++_loadGeneration;
    _inFlight = true;
    _lastAttemptViewport = viewport;

    final previousMarkers = state.mapMarkers;
    final cacheKey = _localCache.keyFor(
      center: viewport.center,
      zoom: viewport.zoom,
      filter: filter,
    );

    final cached = await _localCache.read(cacheKey);
    if (isClosed || generation != _loadGeneration) {
      if (generation == _loadGeneration) _inFlight = false;
      return;
    }

    if (cached != null && cached.isNotEmpty) {
      emit(
        MapMarkersState.loaded(
          markers: cached,
          mapMarkers: _toMapMarkers(cached),
          isFromCache: true,
          isLoading: true,
        ),
      );
    } else {
      emit(
        state.copyWith(
          isLoading: true,
          errorMessage: null,
          mapMarkers: previousMarkers,
        ),
      );
    }

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
      _lastAttemptViewport = viewport;
      _lastErrorAt = null;
      await _localCache.write(cacheKey, page.items);

      if (isClosed || generation != _loadGeneration) return;

      emit(
        MapMarkersState.loaded(
          markers: page.items,
          mapMarkers: _toMapMarkers(page.items),
        ),
      );
    } catch (error) {
      if (isClosed || generation != _loadGeneration) return;
      _lastErrorAt = DateTime.now();
      // Чтобы mapIdle не открывал новый RPC каждые ~300ms после 504.
      _lastAttemptViewport = viewport;
      final keep = state.mapMarkers.isNotEmpty ? state.mapMarkers : previousMarkers;
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: error.toString(),
          mapMarkers: keep,
        ),
      );
    } finally {
      if (generation == _loadGeneration) {
        _inFlight = false;
      }
    }
  }

  @override
  Future<void> close() {
    _settleTimer?.cancel();
    return super.close();
  }

  static List<AppMapMarker> _toMapMarkers(List<MapMarkerItem> items) {
    return [
      for (final item in items)
        AppMapMarker(
          id: item.id,
          point: item.point,
          emoji: item.textEmoji,
        ),
    ];
  }
}

class MapMarkersState {
  const MapMarkersState._({
    required this.isLoading,
    this.markers = const [],
    this.mapMarkers = const [],
    this.errorMessage,
    this.isFromCache = false,
  });

  const MapMarkersState.initial() : this._(isLoading: false);

  const MapMarkersState.loaded({
    required List<MapMarkerItem> markers,
    required List<AppMapMarker> mapMarkers,
    bool isFromCache = false,
    bool isLoading = false,
  }) : this._(
          isLoading: isLoading,
          markers: markers,
          mapMarkers: mapMarkers,
          isFromCache: isFromCache,
        );

  final bool isLoading;
  final List<MapMarkerItem> markers;
  final List<AppMapMarker> mapMarkers;
  final String? errorMessage;
  final bool isFromCache;

  MapMarkersState copyWith({
    bool? isLoading,
    List<MapMarkerItem>? markers,
    List<AppMapMarker>? mapMarkers,
    String? errorMessage,
    bool? isFromCache,
  }) {
    return MapMarkersState._(
      isLoading: isLoading ?? this.isLoading,
      markers: markers ?? this.markers,
      mapMarkers: mapMarkers ?? this.mapMarkers,
      errorMessage: errorMessage,
      isFromCache: isFromCache ?? this.isFromCache,
    );
  }
}
