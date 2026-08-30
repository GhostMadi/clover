import 'package:clover/feature/_catalog_/city/data/models/city_code.dart';
import 'package:clover/feature/_catalog_/countries/data/models/country_code.dart';
import 'package:clover/feature/_catalog_/marker_tags/data/models/marker_tag_model.dart';

/// Краткие данные маркера из `get_post_enriched` → `post.marker`.
class PostMarkerSummary {
  const PostMarkerSummary({
    required this.id,
    required this.textEmoji,
    this.addressPrimary,
    this.addressCyrillic,
    this.countryCode,
    this.cityCode,
    this.eventTime,
    this.endTime,
    this.status,
    this.tags = const [],
  });

  final String id;
  final String textEmoji;
  final String? addressPrimary;
  final String? addressCyrillic;
  final String? countryCode;
  final String? cityCode;
  final DateTime? eventTime;
  final DateTime? endTime;
  final String? status;
  final List<MarkerTagModel> tags;

  String? get countryLabel => CountryCode.tryParse(countryCode)?.labelRu;

  String? get cityLabel {
    final country = countryCode?.trim();
    final city = cityCode?.trim();
    if (country == null || country.isEmpty || city == null || city.isEmpty) return null;
    return CityCode.tryParse(countryCode: country, cityCode: city)?.labelRu ?? city;
  }

  String? get regionLine {
    final country = countryLabel;
    final city = cityLabel;
    if (country != null && city != null) return '$country · $city';
    return country ?? city;
  }

  String? get primaryAddressLine {
    final value = addressPrimary?.trim();
    if (value == null || value.isEmpty) return null;
    return value;
  }

  String? get secondaryAddressLine {
    final primary = primaryAddressLine;
    final cyrillic = addressCyrillic?.trim();
    if (cyrillic == null || cyrillic.isEmpty) return null;
    if (primary != null && primary == cyrillic) return null;
    return cyrillic;
  }

  Duration? get duration {
    final start = eventTime;
    final end = endTime;
    if (start == null || end == null) return null;
    return end.difference(start);
  }

  PostMarkerSummary copyWith({
    String? id,
    String? textEmoji,
    String? addressPrimary,
    String? addressCyrillic,
    String? countryCode,
    String? cityCode,
    DateTime? eventTime,
    DateTime? endTime,
    String? status,
    List<MarkerTagModel>? tags,
  }) {
    return PostMarkerSummary(
      id: id ?? this.id,
      textEmoji: textEmoji ?? this.textEmoji,
      addressPrimary: addressPrimary ?? this.addressPrimary,
      addressCyrillic: addressCyrillic ?? this.addressCyrillic,
      countryCode: countryCode ?? this.countryCode,
      cityCode: cityCode ?? this.cityCode,
      eventTime: eventTime ?? this.eventTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      tags: tags ?? this.tags,
    );
  }

  static PostMarkerSummary? tryFromJson(dynamic raw) {
    if (raw == null || raw is! Map) return null;

    final json = Map<String, dynamic>.from(raw);
    final id = (json['id'] as String?)?.trim();
    if (id == null || id.isEmpty) return null;

    return PostMarkerSummary(
      id: id,
      textEmoji: (json['text_emoji'] as String?)?.trim() ?? '',
      addressPrimary: (json['address_primary'] as String?)?.trim(),
      addressCyrillic: (json['address_cyrillic'] as String?)?.trim(),
      countryCode: (json['country_code'] as String?)?.trim().toLowerCase(),
      cityCode: (json['city_code'] as String?)?.trim(),
      eventTime: _parseDate(json['event_time']),
      endTime: _parseDate(json['end_time']),
      status: (json['status'] as String?)?.trim(),
      tags: _parseTags(json['tags']),
    );
  }

  static List<MarkerTagModel> _parseTags(dynamic raw) {
    if (raw is! List) return const [];

    final tags = <MarkerTagModel>[];
    for (final item in raw) {
      if (item is! Map) continue;
      tags.add(MarkerTagModel.fromJson(Map<String, dynamic>.from(item)));
    }
    return List.unmodifiable(tags);
  }

  static DateTime? _parseDate(dynamic raw) {
    if (raw is! String) return null;
    return DateTime.tryParse(raw);
  }
}
