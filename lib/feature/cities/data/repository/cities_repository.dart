

import 'package:clover/feature/city/data/models/city_model.dart';

abstract class CitiesRepository {
  Future<List<CityModel>> fetchActiveByCountryOrdered(String countryCode);
}
