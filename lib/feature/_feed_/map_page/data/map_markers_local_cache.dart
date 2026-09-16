import 'package:clover/core/shared/app_map/app_map_point.dart';
import 'package:clover/core/storage/domain/repositories/i_app_storage.dart';
import 'package:clover/core/storage/extensions/app_storage_extensions.dart';
import 'package:clover/feature/_catalog_/marker_tags/data/catalog/marker_tags_catalog.dart';
import 'package:clover/feature/_feed_/events_page/data/events_filter_tags.dart';
import 'package:clover/feature/_feed_/events_page/data/models/events_filter.dart';
import 'package:clover/feature/_feed_/map_page/data/map_viewport_query.dart';
import 'package:clover/feature/_feed_/map_page/data/models/map_marker_item.dart';
import 'package:injectable/injectable.dart';

/// Кэш маркеров карты: memory (мгновенно) → disk (stale-while-revalidate).
@lazySingleton
class MapMarkersLocalCache {
  MapMarkersLocalCache(this._storage);

  final IAppStorage _storage;

  static const _maxAge = Duration(hours: 6);
  static const _memoryMaxKeys = 64;

  final Map<String, List<MapMarkerItem>> _memory = {};

  /// Ключ: mode + zoom-bucket + грубая ячейка центра + отпечаток фильтра.
  String keyFor({
    required AppMapPoint center,
    required double zoom,
    required EventsFilter filter,
  }) {
    final radius = MapViewportQuery.radiusM(zoom);
    final cellDeg = (radius * MapViewportQuery.reloadCenterFraction) / 111000.0;
    final safeCell = cellDeg < 0.002 ? 0.002 : cellDeg;
    final latCell = (center.latitude / safeCell).round();
    final lngCell = (center.longitude / safeCell).round();
    final zoomBucket = zoom >= 16
        ? 16
        : zoom >= 14
            ? 14
            : zoom >= 12
                ? 12
                : 10;
    final mode = MapViewportQuery.useServerClusters(zoom) ? 'c' : 'p';
    return 'map_markers_${mode}_z${zoomBucket}_${latCell}_${lngCell}_${_filterFingerprint(filter)}';
  }

  /// Sync — для paint при pan без await.
  List<MapMarkerItem>? peek(String key) => _memory[key];

  /// Текущая ячейка + соседи ±1 (чтобы при скролле назад не ждать disk/RPC).
  List<MapMarkerItem> peekAround({
    required AppMapPoint center,
    required double zoom,
    required EventsFilter filter,
  }) {
    final keys = <String>{keyFor(center: center, zoom: zoom, filter: filter)};
    final radius = MapViewportQuery.radiusM(zoom);
    final cellDeg = (radius * MapViewportQuery.reloadCenterFraction) / 111000.0;
    final safeCell = cellDeg < 0.002 ? 0.002 : cellDeg;
    final latCell = (center.latitude / safeCell).round();
    final lngCell = (center.longitude / safeCell).round();
    final zoomBucket = zoom >= 16
        ? 16
        : zoom >= 14
            ? 14
            : zoom >= 12
                ? 12
                : 10;
    final mode = MapViewportQuery.useServerClusters(zoom) ? 'c' : 'p';
    final fingerprint = _filterFingerprint(filter);

    for (var dLat = -1; dLat <= 1; dLat++) {
      for (var dLng = -1; dLng <= 1; dLng++) {
        if (dLat == 0 && dLng == 0) continue;
        keys.add(
          'map_markers_${mode}_z${zoomBucket}_${latCell + dLat}_${lngCell + dLng}_$fingerprint',
        );
      }
    }

    final byId = <String, MapMarkerItem>{};
    for (final key in keys) {
      final items = _memory[key];
      if (items == null) continue;
      for (final item in items) {
        final id = item.id.isEmpty
            ? 'c_${item.lat.toStringAsFixed(5)}_${item.lng.toStringAsFixed(5)}'
            : item.id;
        byId[id] = item;
      }
    }
    return byId.values.toList(growable: false);
  }

  Future<List<MapMarkerItem>?> read(String key) async {
    final mem = _memory[key];
    if (mem != null) return mem;

    final raw = await _storage.readObject<Map<String, dynamic>>(
      key: key,
      fromJson: (json) => json,
    );
    if (raw == null) return null;

    final savedAtRaw = raw['saved_at'];
    final savedAt = savedAtRaw is String ? DateTime.tryParse(savedAtRaw)?.toUtc() : null;
    if (savedAt != null && DateTime.now().toUtc().difference(savedAt) > _maxAge) {
      await _storage.delete(key: key);
      return null;
    }

    final list = raw['items'];
    if (list is! List) return null;
    final items = <MapMarkerItem>[];
    for (final row in list) {
      if (row is! Map) continue;
      items.add(MapMarkerItem.fromJson(Map<String, dynamic>.from(row)));
    }
    _putMemory(key, items);
    return items;
  }

  Future<void> write(String key, List<MapMarkerItem> items) async {
    _putMemory(key, items);
    await _storage.writeObject<Map<String, dynamic>>(
      key: key,
      value: {
        'saved_at': DateTime.now().toUtc().toIso8601String(),
        'items': [for (final item in items) item.toJson()],
      },
      toJson: (v) => v,
    );
  }

  void clearMemory() => _memory.clear();

  void _putMemory(String key, List<MapMarkerItem> items) {
    _memory.remove(key);
    _memory[key] = List<MapMarkerItem>.unmodifiable(items);
    while (_memory.length > _memoryMaxKeys) {
      _memory.remove(_memory.keys.first);
    }
  }

  static String _filterFingerprint(EventsFilter filter) {
    final tagKeys = filter.tagIds.isEmpty
        ? const <String>[]
        : (EventsFilterTags.keysFor(filter.tagIds, MarkerTagsCatalog.all).toList()..sort());
    final from = filter.dateFrom?.toUtc().toIso8601String() ?? '';
    final to = filter.dateTo?.toUtc().toIso8601String() ?? '';
    return [
      filter.countryCode?.trim() ?? '',
      filter.cityCode?.trim() ?? '',
      filter.emoji?.trim() ?? '',
      tagKeys.join(','),
      from,
      to,
    ].join('|');
  }
}
