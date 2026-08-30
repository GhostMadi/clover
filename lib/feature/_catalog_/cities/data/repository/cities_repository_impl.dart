import 'package:clover/feature/_catalog_/city/data/catalog/cities_catalog.dart';
import 'package:clover/feature/_catalog_/city/data/models/city_model.dart';
import 'package:clover/feature/_catalog_/cities/data/repository/cities_repository.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: CitiesRepository)
class CitiesRepositoryImpl implements CitiesRepository {
  @override
  Future<List<CityModel>> fetchActiveByCountryOrdered(String countryCode) async {
    return CitiesCatalog.modelsForCountry(countryCode);
  }
}
