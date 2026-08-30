import 'package:clover/feature/_catalog_/countries/data/models/country_code.dart';
import 'package:clover/feature/_catalog_/countries/data/models/country_model.dart';

/// Страна: enum + поля справочника (`is_active`, `sort_order`).
class CountryRef {
  const CountryRef({
    required this.code,
    this.isActive = true,
    required this.sortOrder,
  });

  final CountryCode code;
  final bool isActive;
  final int sortOrder;

  CountryModel toModel() => CountryModel(
        code: code.code,
        isActive: isActive,
        sortOrder: sortOrder,
      );
}
