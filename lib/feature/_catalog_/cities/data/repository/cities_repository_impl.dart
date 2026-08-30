import 'package:clover/core/catalog_sync/domain/catalog_sync_manager.dart';
import 'package:clover/feature/city/data/models/city_model.dart';
import 'package:clover/feature/cities/data/repository/cities_repository.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: CitiesRepository)
class CitiesRepositoryImpl implements CitiesRepository {
  CitiesRepositoryImpl(this._catalogSync);

  final CatalogSyncManager _catalogSync;

  @override
  Future<List<CityModel>> fetchActiveByCountryOrdered(String countryCode) async {
    final code = countryCode.trim().toLowerCase();
    final all = await _catalogSync.cities();
    return all.where((city) => city.countryCode == code).toList(growable: false);
  }
}
