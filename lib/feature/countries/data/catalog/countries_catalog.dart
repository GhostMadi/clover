import 'package:clover/feature/city/data/catalog/cities_catalog.dart';
import 'package:clover/feature/city/data/models/city_ref.dart';
import 'package:clover/feature/countries/data/models/country_code.dart';
import 'package:clover/feature/countries/data/models/country_model.dart';
import 'package:clover/feature/countries/data/models/country_ref.dart';
import 'package:clover/feature/countries/data/models/country_with_cities.dart';

/// Справочник стран (данные как в `public.countries`) + связь с городами.
abstract final class CountriesCatalog {
  static const countries = <CountryRef>[
    CountryRef(code: CountryCode.kz, sortOrder: 1),
    CountryRef(code: CountryCode.ru, sortOrder: 2),
  ];

  static List<CountryModel> get models => countries.map((e) => e.toModel()).toList(growable: false);

  static List<CountryWithCities> get withCities {
    return countries
        .map(
          (country) => CountryWithCities(
            country: country,
            cities: CitiesCatalog.forCountry(country.code),
          ),
        )
        .toList(growable: false);
  }

  static List<CityRef> citiesFor(CountryCode country) => CitiesCatalog.forCountry(country);
}
