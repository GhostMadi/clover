import 'dart:async';
import 'dart:math' as math;

import 'package:clover/core/shared/app_map/app_map_marker.dart';
import 'package:clover/core/shared/app_map/app_map_point.dart';
import 'package:clover/core/shared/app_map/app_map_viewport.dart';
import 'package:clover/feature/_feed_/events_page/data/models/events_filter.dart';
import 'package:clover/feature/_feed_/map_page/data/map_markers_local_cache.dart';
import 'package:clover/feature/_feed_/map_page/data/map_viewport_query.dart';
import 'package:clover/feature/_feed_/map_page/data/models/map_marker_item.dart';
import 'package:clover/feature/_feed_/map_page/data/repository/map_markers_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

/// Маркеры в viewport: memory → disk → RPC (stale-while-revalidate).
///
/// Точки копятся в пуле по id: при скролле назад рисуются сразу из памяти,
/// сеть только догружает / освежает. Кластеры (zoom &lt; 13) — по ячейкам кэша.
@injectable
class MapMarkersCubit extends Cubit<MapMarkersState> {
  MapMarkersCubit(this._repository, this._localCache) : super(const MapMarkersState.initial());

  final MapMarkersRepository _repository;
  final MapMarkersLocalCache _localCache;

  static const _settleDebounce = Duration(milliseconds: 280);
  static const _errorCooldown = Duration(seconds: 8);
  static const _visibleRadiusFactor = 1.4;
  static const _pointsPoolCap = 2500;

  int _loadGeneration = 0;
  AppMapViewport? _lastFetchedViewport;
  AppMapViewport? _lastAttemptViewport;
  DateTime? _lastErrorAt;
  EventsFilter? _filter;
  bool _inFlight = false;
  Timer? _settleTimer;

  /// Накопленные точки (zoom ≥ 13). Не смешиваем с server clusters.
  final Map<String, MapMarkerItem> _pointsById = {};

  Future<void> load({
    required AppMapViewport viewport,
    required EventsFilter filter,
    bool force = false,
  }) async {
    if (_filter != filter) {
      _filter = filter;
      _pointsById.clear();
      _localCache.clearMemory();
      _lastFetchedViewport = null;
      _lastAttemptViewport = null;
    } else {
      _filter = filter;
    }
    _settleTimer?.cancel();

    if (!force && !_shouldStartFetch(viewport)) {
      _emitFromMemory(viewport);
      return;
    }
    if (_inFlight && !force) {
      _emitFromMemory(viewport);
      return;
    }

    await _fetchViewport(viewport);
  }

  /// Во время pan/zoom — сразу показать то, что уже в memory/пуле (без RPC).
  void onViewportMoved(AppMapViewport viewport) {
    if (_filter == null) return;
    _emitFromMemory(viewport);
  }

  /// Камера остановилась — сеть, если ушли достаточно далеко / zoom.
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
      if (DateTime.now().difference(erred) < _errorCooldown) return false;
    }
    return true;
  }

  void _emitFromMemory(AppMapViewport viewport) {
    final filter = _filter;
    if (filter == null || isClosed) return;

    if (MapViewportQuery.useServerClusters(viewport.zoom)) {
      final cached = _localCache.peekAround(center: viewport.center, zoom: viewport.zoom, filter: filter);
      if (cached.isEmpty) return;
      if (_sameItemIds(cached, state.markers)) return;
      emit(
        MapMarkersState.loaded(
          markers: cached,
          mapMarkers: _toMapMarkers(cached),
          isFromCache: true,
        ),
      );
      return;
    }

    final visible = _visiblePoints(viewport);
    if (visible.isEmpty) return;
    if (_sameItemIds(visible, state.markers)) return;
    emit(
      MapMarkersState.loaded(
        markers: visible,
        mapMarkers: _toMapMarkers(visible),
        isFromCache: true,
      ),
    );
  }

  static bool _sameItemIds(List<MapMarkerItem> next, List<MapMarkerItem> current) {
    if (next.length != current.length) return false;
    final currentIds = <String>{
      for (final item in current)
        item.id.isEmpty
            ? 'c_${item.lat.toStringAsFixed(5)}_${item.lng.toStringAsFixed(5)}'
            : item.id,
    };
    for (final item in next) {
      final id = item.id.isEmpty
          ? 'c_${item.lat.toStringAsFixed(5)}_${item.lng.toStringAsFixed(5)}'
          : item.id;
      if (!currentIds.contains(id)) return false;
    }
    return true;
  }

  Future<void> _fetchViewport(AppMapViewport viewport) async {
    final filter = _filter;
    if (filter == null) return;

    final generation = ++_loadGeneration;
    _inFlight = true;
    _lastAttemptViewport = viewport;

    final cacheKey = _localCache.keyFor(
      center: viewport.center,
      zoom: viewport.zoom,
      filter: filter,
    );

    // 1) Sync memory / pool — без мигания пустой карты.
    _emitFromMemory(viewport);
    if (isClosed || generation != _loadGeneration) {
      if (generation == _loadGeneration) _inFlight = false;
      return;
    }

    // 2) Disk (если memory miss) — всё ещё до сети.
    final peeked = _localCache.peek(cacheKey);
    if (peeked == null) {
      final cached = await _localCache.read(cacheKey);
      if (isClosed || generation != _loadGeneration) {
        if (generation == _loadGeneration) _inFlight = false;
        return;
      }
      if (cached != null && cached.isNotEmpty) {
        if (!MapViewportQuery.useServerClusters(viewport.zoom)) {
          _mergePoints(cached);
        }
        _emitLoaded(viewport, isFromCache: true, isLoading: true);
      } else {
        emit(state.copyWith(isLoading: true, errorMessage: null));
      }
    } else {
      emit(state.copyWith(isLoading: true, errorMessage: null));
    }

    try {
      final items = await _loadItems(viewport: viewport, filter: filter);

      if (isClosed || generation != _loadGeneration) return;

      _lastFetchedViewport = viewport;
      _lastAttemptViewport = viewport;
      _lastErrorAt = null;
      await _localCache.write(cacheKey, items);

      if (!MapViewportQuery.useServerClusters(viewport.zoom)) {
        _mergePoints(items);
      }

      if (isClosed || generation != _loadGeneration) return;

      _emitLoaded(viewport, isFromCache: false, isLoading: false);

      unawaited(_prefetchNeighbors(viewport: viewport, filter: filter));
    } catch (error) {
      if (isClosed || generation != _loadGeneration) return;
      _lastErrorAt = DateTime.now();
      _lastAttemptViewport = viewport;
      _emitFromMemory(viewport);
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: error.toString(),
        ),
      );
    } finally {
      if (generation == _loadGeneration) {
        _inFlight = false;
      }
    }
  }

  void _emitLoaded(AppMapViewport viewport, {required bool isFromCache, required bool isLoading}) {
    if (MapViewportQuery.useServerClusters(viewport.zoom)) {
      final filter = _filter;
      if (filter == null) return;
      final items = _localCache.peekAround(center: viewport.center, zoom: viewport.zoom, filter: filter);
      emit(
        MapMarkersState.loaded(
          markers: items,
          mapMarkers: _toMapMarkers(items),
          isFromCache: isFromCache,
          isLoading: isLoading,
        ),
      );
      return;
    }

    final visible = _visiblePoints(viewport);
    emit(
      MapMarkersState.loaded(
        markers: visible,
        mapMarkers: _toMapMarkers(visible),
        isFromCache: isFromCache,
        isLoading: isLoading,
      ),
    );
  }

  void _mergePoints(List<MapMarkerItem> items) {
    for (final item in items) {
      if (item.pointCount != null) continue;
      final id = item.id.isEmpty
          ? '${item.lat.toStringAsFixed(5)}_${item.lng.toStringAsFixed(5)}_${item.textEmoji}'
          : item.id;
      _pointsById[id] = item;
    }
    _prunePointsPool();
  }

  void _prunePointsPool() {
    if (_pointsById.length <= _pointsPoolCap) return;
    final center = _lastFetchedViewport?.center ?? _lastAttemptViewport?.center;
    if (center == null) {
      final keys = _pointsById.keys.take(_pointsById.length - _pointsPoolCap).toList();
      for (final key in keys) {
        _pointsById.remove(key);
      }
      return;
    }
    final ranked = _pointsById.entries.toList()
      ..sort(
        (a, b) => MapViewportQuery.distanceM(center, a.value.point)
            .compareTo(MapViewportQuery.distanceM(center, b.value.point)),
      );
    _pointsById
      ..clear()
      ..addEntries(ranked.take(_pointsPoolCap));
  }

  List<MapMarkerItem> _visiblePoints(AppMapViewport viewport) {
    final maxDist = MapViewportQuery.radiusM(viewport.zoom) * _visibleRadiusFactor;
    return [
      for (final item in _pointsById.values)
        if (MapViewportQuery.distanceM(viewport.center, item.point) <= maxDist) item,
    ];
  }

  Future<List<MapMarkerItem>> _loadItems({
    required AppMapViewport viewport,
    required EventsFilter filter,
  }) async {
    final limit = MapViewportQuery.limit(viewport.zoom);
    if (MapViewportQuery.useServerClusters(viewport.zoom)) {
      return _repository.fetchClusters(
        center: viewport.center,
        zoom: viewport.zoom,
        filter: filter,
        limit: limit,
      );
    }

    final page = await _repository.fetchPage(
      center: viewport.center,
      zoom: viewport.zoom,
      filter: filter,
      offset: 0,
      limit: limit,
    );
    return page.items;
  }

  /// Warm memory+disk for N/S/E/W neighbors (~0.5 query radius). No UI emit.
  Future<void> _prefetchNeighbors({
    required AppMapViewport viewport,
    required EventsFilter filter,
  }) async {
    final radius = MapViewportQuery.radiusM(viewport.zoom);
    final stepM = radius * 0.5;
    final latRad = viewport.center.latitude * math.pi / 180;
    final dLat = stepM / 111320.0;
    final dLng = stepM / (111320.0 * math.max(0.2, math.cos(latRad)));

    final neighbors = <AppMapPoint>[
      AppMapPoint(latitude: viewport.center.latitude + dLat, longitude: viewport.center.longitude),
      AppMapPoint(latitude: viewport.center.latitude - dLat, longitude: viewport.center.longitude),
      AppMapPoint(latitude: viewport.center.latitude, longitude: viewport.center.longitude + dLng),
      AppMapPoint(latitude: viewport.center.latitude, longitude: viewport.center.longitude - dLng),
    ];

    for (final center in neighbors) {
      if (isClosed) return;
      final key = _localCache.keyFor(center: center, zoom: viewport.zoom, filter: filter);
      if (_localCache.peek(key) != null) continue;

      final existing = await _localCache.read(key);
      if (existing != null && existing.isNotEmpty) {
        if (!MapViewportQuery.useServerClusters(viewport.zoom)) {
          _mergePoints(existing);
        }
        continue;
      }

      try {
        final items = await _loadItems(
          viewport: AppMapViewport(center: center, zoom: viewport.zoom),
          filter: filter,
        );
        if (isClosed) return;
        await _localCache.write(key, items);
        if (!MapViewportQuery.useServerClusters(viewport.zoom)) {
          _mergePoints(items);
        }
      } catch (_) {
        // Prefetch is best-effort.
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
          id: item.id.isEmpty
              ? 'c_${item.lat.toStringAsFixed(5)}_${item.lng.toStringAsFixed(5)}'
              : item.id,
          point: item.point,
          emoji: item.textEmoji.isEmpty ? '📍' : item.textEmoji,
          clusterCount: item.pointCount,
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
