import 'package:clover/core/catalog_sync/domain/catalog_sync_manager.dart';
import 'package:clover/feature/currencies/data/models/currency_model.dart';
import 'package:clover/feature/currencies/data/repository/currencies_repository.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: CurrenciesRepository)
class CurrenciesRepositoryImpl implements CurrenciesRepository {
  CurrenciesRepositoryImpl(this._catalogSync);

  final CatalogSyncManager _catalogSync;

  @override
  Future<List<CurrencyModel>> fetchActiveOrdered() {
    return _catalogSync.currencies();
  }
}
