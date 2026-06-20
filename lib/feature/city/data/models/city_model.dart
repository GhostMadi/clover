import 'package:clover/feature/city/data/models/city_code.dart';

/// Строка `public.cities`.
class CityModel {
  const CityModel({
    required this.countryCode,
    required this.cityCode,
    required this.isActive,
    required this.sortOrder,
  });

  final String countryCode;
  final String cityCode;
  final bool isActive;
  final int sortOrder;

  CityCode? get asEnum => CityCode.tryParse(countryCode: countryCode, cityCode: cityCode);

  factory CityModel.fromJson(Map<String, dynamic> json) {
    return CityModel(
      countryCode: (json['country_code'] as String).trim().toLowerCase(),
      cityCode: (json['city_code'] as String).trim(),
      isActive: json['is_active'] as bool? ?? true,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );
  }
}
