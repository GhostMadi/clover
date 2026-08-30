import 'package:clover/feature/_catalog_/city/data/models/city_model.dart';
import 'package:clover/feature/_catalog_/city/data/models/city_ref.dart';
import 'package:clover/feature/_catalog_/countries/data/models/country_model.dart';
import 'package:clover/feature/_catalog_/countries/data/models/country_ref.dart';

/// Страна и её города одним объектом.
class CountryWithCities {
  const CountryWithCities({
    required this.country,
    required this.cities,
  });

  final CountryRef country;
  final List<CityRef> cities;

  CountryModel get countryModel => country.toModel();

  List<CityModel> get cityModels => cities.map((e) => e.toModel()).toList(growable: false);
}
