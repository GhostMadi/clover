import 'package:clover/feature/_catalog_/countries/data/models/country_code.dart';

/// Строка `public.countries`.
class CountryModel {
  const CountryModel({
    required this.code,
    required this.isActive,
    required this.sortOrder,
  });

  final String code;
  final bool isActive;
  final int sortOrder;

  CountryCode? get asEnum => CountryCode.tryParse(code);

  factory CountryModel.fromJson(Map<String, dynamic> json) {
    return CountryModel(
      code: json['code'] as String,
      isActive: json['is_active'] as bool? ?? true,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'code': code,
    'is_active': isActive,
    'sort_order': sortOrder,
  };
}
