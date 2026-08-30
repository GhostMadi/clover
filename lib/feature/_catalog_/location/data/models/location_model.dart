import 'package:clover/feature/_catalog_/city/data/models/city_code.dart';
import 'package:clover/feature/_catalog_/countries/data/models/country_code.dart';

/// Местоположение пользователя / магазина.
class LocationModel {
  const LocationModel({
    required this.id,
    required this.addressPrimary,
    this.addressCyrillic,
    this.countryCode,
    this.cityCode,
    this.isActive = true,
    this.latitude,
    this.longitude,
  });

  final String id;

  /// Основной адрес (латиница при создании).
  final String addressPrimary;

  /// Адрес кириллицей (необязательно).
  final String? addressCyrillic;

  final String? countryCode;
  final String? cityCode;
  final bool isActive;
  final double? latitude;
  final double? longitude;

  bool get hasGeoBinding {
    final country = countryCode?.trim();
    final city = cityCode?.trim();
    return country != null && country.isNotEmpty && city != null && city.isNotEmpty;
  }

  /// Заголовок в списке — кириллица, иначе основной адрес.
  String get displayTitle {
    final cyrillic = addressCyrillic?.trim();
    if (cyrillic != null && cyrillic.isNotEmpty) return cyrillic;
    return addressPrimary.trim();
  }

  /// Подзаголовок: второй адрес + статус привязки страны/города.
  String get displaySubtitle {
    final parts = <String>[];

    final primary = addressPrimary.trim();
    final cyrillic = addressCyrillic?.trim();
    final hasCyrillic = cyrillic != null && cyrillic.isNotEmpty;

    if (hasCyrillic && primary.isNotEmpty && primary != cyrillic) {
      parts.add(primary);
    }

    parts.add(hasGeoBinding ? geoBindingLabel : 'Страна и город не привязаны');
    return parts.join(' · ');
  }

  String get geoBindingLabel {
    final country = CountryCode.tryParse(countryCode);
    final city = country == null
        ? null
        : CityCode.tryParse(countryCode: country.code, cityCode: cityCode ?? '');

    if (country == null || city == null) return 'Страна и город не привязаны';
    return '${country.labelRu}, ${city.labelRu}';
  }

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    double? coord(String key) {
      final v = json[key];
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    final countryRaw = json['country_code'];
    final cityRaw = json['city_code'];

    return LocationModel(
      id: json['id'] as String,
      addressPrimary: (json['address_primary'] as String?)?.trim() ?? '',
      addressCyrillic: (json['address_cyrillic'] as String?)?.trim(),
      countryCode: countryRaw?.toString().trim().toLowerCase(),
      cityCode: cityRaw?.toString().trim(),
      isActive: json['is_active'] as bool? ?? true,
      latitude: coord('latitude'),
      longitude: coord('longitude'),
    );
  }

  LocationModel copyWith({
    String? addressPrimary,
    String? addressCyrillic,
    String? countryCode,
    String? cityCode,
    bool clearCountryCode = false,
    bool clearCityCode = false,
    bool? isActive,
    double? latitude,
    double? longitude,
  }) {
    return LocationModel(
      id: id,
      addressPrimary: addressPrimary ?? this.addressPrimary,
      addressCyrillic: addressCyrillic ?? this.addressCyrillic,
      countryCode: clearCountryCode ? null : (countryCode ?? this.countryCode),
      cityCode: clearCityCode ? null : (cityCode ?? this.cityCode),
      isActive: isActive ?? this.isActive,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}
