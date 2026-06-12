

import 'package:clover/feature/countries/data/models/country_code.dart';

/// Slug города как в `public.cities.city_code` (строки совпадают с БД).
enum CityCode {
  almaty('kz', 'almaty', 'Алматы'),
  astana('kz', 'astana', 'Астана'),
  shymkent('kz', 'shymkent', 'Шымкент'),
  kazan('ru', 'kazan', 'Казань'),
  moscow('ru', 'moscow', 'Москва'),
  saintPetersburg('ru', 'saintPetersburg', 'Санкт-Петербург');

  const CityCode(this.countryCode, this.cityCode, this.labelRu);

  final String countryCode;
  final String cityCode;
  final String labelRu;

  CountryCode get country => CountryCode.tryParse(countryCode)!;

  static CityCode? tryParse({required String countryCode, required String cityCode}) {
    final cc = countryCode.trim().toLowerCase();
    final cy = cityCode.trim();
    for (final v in CityCode.values) {
      if (v.countryCode == cc && _ciEq(v.cityCode, cy)) return v;
    }
    return null;
  }

  static bool _ciEq(String a, String b) => a.toLowerCase() == b.toLowerCase();
}
