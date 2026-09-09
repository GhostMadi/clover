import 'package:clover/core/shared/app_map/app_map_point.dart';
import 'package:clover/core/storage/domain/repositories/i_app_storage.dart';
import 'package:clover/core/storage/extensions/app_storage_extensions.dart';
import 'package:clover/feature/_catalog_/marker_tags/data/catalog/marker_tags_catalog.dart';
import 'package:clover/feature/_feed_/events_page/data/events_filter_tags.dart';
import 'package:clover/feature/_feed_/events_page/data/models/events_filter.dart';
import 'package:clover/feature/_feed_/map_page/data/map_viewport_query.dart';
import 'package:clover/feature/_feed_/map_page/data/models/map_marker_item.dart';
import 'package:injectable/injectable.dart';

/// Дисковый кэш маркеров карты (stale-while-revalidate по viewport-ячейке).
@lazySingleton
class MapMarkersLocalCache {
  MapMarkersLocalCache(this._storage);

  final IAppStorage _storage;

  static const _maxAge = Duration(hours: 6);

  /// Ключ: zoom-bucket + грубая ячейка центра + отпечаток фильтра.
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
    return 'map_markers_z${zoomBucket}_${latCell}_${lngCell}_${_filterFingerprint(filter)}';
  }

  Future<List<MapMarkerItem>?> read(String key) async {
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
    return items;
  }

  Future<void> write(String key, List<MapMarkerItem> items) async {
    await _storage.writeObject<Map<String, dynamic>>(
      key: key,
      value: {
        'saved_at': DateTime.now().toUtc().toIso8601String(),
        'items': [for (final item in items) item.toJson()],
      },
      toJson: (v) => v,
    );
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
