import 'package:clover/core/catalog_sync/domain/catalog_sync_manager.dart';
import 'package:clover/feature/countries/data/models/country_model.dart';
import 'package:clover/feature/countries/data/repository/countries_repository.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: CountriesRepository)
class CountriesRepositoryImpl implements CountriesRepository {
  CountriesRepositoryImpl(this._catalogSync);

  final CatalogSyncManager _catalogSync;

  @override
  Future<List<CountryModel>> fetchActiveOrdered() {
    return _catalogSync.countries();
  }
}
