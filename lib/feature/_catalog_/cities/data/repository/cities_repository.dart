

import 'package:clover/feature/_catalog_/city/data/models/city_model.dart';

abstract class CitiesRepository {
  Future<List<CityModel>> fetchActiveByCountryOrdered(String countryCode);
}
