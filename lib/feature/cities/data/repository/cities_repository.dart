

import 'package:clover/feature/cities/data/models/city_model.dart';

abstract class CitiesRepository {
  Future<List<CityModel>> fetchActiveByCountryOrdered(String countryCode);
}
