import 'package:clover/feature/city/data/models/city_code.dart';
import 'package:clover/feature/city/data/models/city_model.dart';

/// Город: enum + поля справочника (`is_active`, `sort_order`).
class CityRef {
  const CityRef({
    required this.code,
    this.isActive = true,
    required this.sortOrder,
  });

  final CityCode code;
  final bool isActive;
  final int sortOrder;

  CityModel toModel() => CityModel(
        countryCode: code.countryCode,
        cityCode: code.cityCode,
        isActive: isActive,
        sortOrder: sortOrder,
      );
}
