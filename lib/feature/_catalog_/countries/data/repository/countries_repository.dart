import 'package:clover/feature/countries/data/models/country_model.dart';

abstract class CountriesRepository {
  Future<List<CountryModel>> fetchActiveOrdered();
}
