import 'package:clover/feature/map_page/data/models/map_marker_item.dart';

class MapMarkersPageResult {
  const MapMarkersPageResult({
    required this.items,
    required this.totalCount,
  });

  final List<MapMarkerItem> items;
  final int totalCount;
}
