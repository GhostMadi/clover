import 'package:clover/feature/city/data/models/city_code.dart';
import 'package:clover/feature/city/data/models/city_model.dart';
import 'package:clover/feature/city/data/models/city_ref.dart';
import 'package:clover/feature/countries/data/models/country_code.dart';

/// Справочник городов (данные как в `public.cities`).
abstract final class CitiesCatalog {
  static const cities = <CityRef>[
    CityRef(code: CityCode.almaty, sortOrder: 1),
    CityRef(code: CityCode.astana, sortOrder: 2),
    CityRef(code: CityCode.shymkent, sortOrder: 3),
    CityRef(code: CityCode.moscow, sortOrder: 1),
    CityRef(code: CityCode.saintPetersburg, sortOrder: 2),
    CityRef(code: CityCode.kazan, sortOrder: 3),
  ];

  static List<CityModel> get models => cities.map((e) => e.toModel()).toList(growable: false);

  static List<CityRef> forCountry(CountryCode country) {
    return cities.where((city) => city.code.country == country).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  static List<CityRef> forCountryCode(String countryCode) {
    final country = CountryCode.tryParse(countryCode);
    if (country == null) return const [];
    return forCountry(country);
  }

  static List<CityModel> modelsForCountry(String countryCode) {
    return forCountryCode(countryCode).map((e) => e.toModel()).toList(growable: false);
  }
}
