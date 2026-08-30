import 'package:clover/core/shared/app_map/app_map_point.dart';
import 'package:clover/feature/_catalog_/marker_tags/data/catalog/marker_tags_catalog.dart';
import 'package:clover/feature/_feed_/events_page/data/events_filter_tags.dart';
import 'package:clover/feature/_feed_/events_page/data/models/events_filter.dart';
import 'package:clover/feature/_feed_/map_page/data/map_viewport_query.dart';
import 'package:clover/feature/_feed_/map_page/data/models/map_marker_item.dart';
import 'package:clover/feature/_feed_/map_page/data/models/map_markers_page_result.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class MapMarkersRepository {
  Future<MapMarkersPageResult> fetchPage({
    required AppMapPoint center,
    required double zoom,
    required EventsFilter filter,
    required int offset,
    required int limit,
  });

  Future<int> countMarkers({required AppMapPoint center, required double zoom, required EventsFilter filter});
}

@LazySingleton(as: MapMarkersRepository)
class MapMarkersRepositoryImpl implements MapMarkersRepository {
  MapMarkersRepositoryImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<MapMarkersPageResult> fetchPage({
    required AppMapPoint center,
    required double zoom,
    required EventsFilter filter,
    required int offset,
    required int limit,
  }) async {
    final params = _rpcParams(center: center, zoom: zoom, filter: filter)
      ..addAll({'p_limit': limit, 'p_offset': offset});

    final res = await _client.rpc('list_markers_map', params: params);
    final rows = res as List<dynamic>? ?? const [];
    final items = rows.map((row) => MapMarkerItem.fromJson(Map<String, dynamic>.from(row as Map))).toList();

    return MapMarkersPageResult(items: _applyDateFilter(items, filter), totalCount: 0);
  }

  @override
  Future<int> countMarkers({
    required AppMapPoint center,
    required double zoom,
    required EventsFilter filter,
  }) async {
    final params = _rpcParams(center: center, zoom: zoom, filter: filter);
    final res = await _client.rpc('count_markers_map', params: params);
    final total = (res as num?)?.toInt() ?? 0;
    return _adjustTotalForDateFilter(total, filter);
  }

  Map<String, dynamic> _rpcParams({
    required AppMapPoint center,
    required double zoom,
    required EventsFilter filter,
  }) {
    final emoji = filter.emoji?.trim();
    final country = filter.countryCode?.trim();
    final city = filter.cityCode?.trim();
    final tagKeys = filter.tagIds.isEmpty
        ? const <String>[]
        : EventsFilterTags.keysFor(filter.tagIds, MarkerTagsCatalog.all);

    return <String, dynamic>{
      'p_lat': center.latitude,
      'p_lng': center.longitude,
      'p_radius_m': MapViewportQuery.radiusM(zoom),
      'p_at_time': DateTime.now().toUtc().toIso8601String(),
      if (emoji != null && emoji.isNotEmpty) 'p_emoji': emoji,
      if (country != null && country.isNotEmpty) 'p_country_code': country,
      if (city != null && city.isNotEmpty) 'p_city_code': city,
      if (tagKeys.isNotEmpty) 'p_tag_keys': tagKeys,
    };
  }

  List<MapMarkerItem> _applyDateFilter(List<MapMarkerItem> markers, EventsFilter filter) {
    var result = markers;

    if (filter.dateFrom != null) {
      result = result
          .where((marker) => marker.eventTime != null && !marker.eventTime!.isBefore(filter.dateFrom!))
          .toList();
    }

    if (filter.dateTo != null) {
      final end = DateTime(filter.dateTo!.year, filter.dateTo!.month, filter.dateTo!.day, 23, 59, 59);
      result = result.where((marker) => marker.eventTime != null && !marker.eventTime!.isAfter(end)).toList();
    }

    return result;
  }

  int _adjustTotalForDateFilter(int total, EventsFilter filter) {
    if (filter.dateFrom == null && filter.dateTo == null) return total;
    return total;
  }
}
