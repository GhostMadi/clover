import 'package:clover/core/shared/app_map/app_map_point.dart';

/// Маркер для карты из `list_markers_map` / `list_markers_map_clusters`.
class MapMarkerItem {
  const MapMarkerItem({
    required this.id,
    required this.textEmoji,
    required this.lat,
    required this.lng,
    this.postId,
    this.countryCode,
    this.cityCode,
    this.eventTime,
    this.status,
    this.pointCount,
  });

  final String id;
  final String textEmoji;
  final double lat;
  final double lng;
  final String? postId;
  final String? countryCode;
  final String? cityCode;
  final DateTime? eventTime;
  final String? status;

  /// Server cluster size from `list_markers_map_clusters`.
  final int? pointCount;

  bool get isServerCluster => pointCount != null && pointCount! >= 1;

  AppMapPoint get point => AppMapPoint(latitude: lat, longitude: lng);

  factory MapMarkerItem.fromJson(Map<String, dynamic> json) {
    final sampleId = json['sample_marker_id'] ?? json['id'];
    final countRaw = json['point_count'];
    return MapMarkerItem(
      id: sampleId == null ? '' : sampleId.toString(),
      textEmoji: (json['text_emoji'] as String?)?.trim() ??
          (json['sample_emoji'] as String?)?.trim() ??
          '',
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      postId: json['post_id'] as String?,
      countryCode: json['country_code'] as String?,
      cityCode: json['city_code'] as String?,
      eventTime: _parseDate(json['event_time']),
      status: json['status'] as String?,
      pointCount: countRaw is num ? countRaw.toInt() : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'text_emoji': textEmoji,
    'lat': lat,
    'lng': lng,
    if (postId != null) 'post_id': postId,
    if (countryCode != null) 'country_code': countryCode,
    if (cityCode != null) 'city_code': cityCode,
    if (eventTime != null) 'event_time': eventTime!.toIso8601String(),
    if (status != null) 'status': status,
    if (pointCount != null) 'point_count': pointCount,
  };

  static DateTime? _parseDate(Object? raw) {
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString())?.toUtc();
  }
}
