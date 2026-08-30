import 'package:clover/feature/_catalog_/countries/data/catalog/countries_catalog.dart';
import 'package:clover/feature/_catalog_/countries/data/models/country_model.dart';
import 'package:clover/feature/_catalog_/countries/data/repository/countries_repository.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: CountriesRepository)
class CountriesRepositoryImpl implements CountriesRepository {
  @override
  Future<List<CountryModel>> fetchActiveOrdered() async {
    return CountriesCatalog.models;
  }
}
