import 'package:clover/core/shared/app_map/app_map_point.dart';

/// Маркер для карты из `list_markers_map` (без постов).
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

  AppMapPoint get point => AppMapPoint(latitude: lat, longitude: lng);

  factory MapMarkerItem.fromJson(Map<String, dynamic> json) {
    return MapMarkerItem(
      id: json['id'] as String,
      textEmoji: (json['text_emoji'] as String?)?.trim() ?? '',
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      postId: json['post_id'] as String?,
      countryCode: json['country_code'] as String?,
      cityCode: json['city_code'] as String?,
      eventTime: _parseDate(json['event_time']),
      status: json['status'] as String?,
    );
  }

  static DateTime? _parseDate(Object? raw) {
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString())?.toUtc();
  }
}
