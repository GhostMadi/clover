import 'package:clover/feature/_catalog_/countries/data/models/country_model.dart';

abstract class CountriesRepository {
  Future<List<CountryModel>> fetchActiveOrdered();
}
