import 'package:clover/core/shared/app_map/app_map_point.dart';
import 'package:flutter/material.dart';

/// Точка маркера на карте.
class AppMapMarker {
  const AppMapMarker({
    required this.id,
    required this.point,
    required this.emoji,
    this.borderColor,
    this.clusterCount,
  });

  final String id;
  final AppMapPoint point;
  final String emoji;
  final Color? borderColor;

  /// Server LOD cluster (`list_markers_map_clusters`). Null = single / stack point.
  final int? clusterCount;

  bool get isServerCluster => clusterCount != null && clusterCount! >= 1;
}
