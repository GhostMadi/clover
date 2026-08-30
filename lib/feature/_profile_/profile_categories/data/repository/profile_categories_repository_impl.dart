import 'package:clover/core/catalog_sync/domain/catalog_sync_manager.dart';
import 'package:clover/feature/profile_categories/data/models/profile_category_model.dart';
import 'package:clover/feature/profile_categories/data/repository/profile_categories_repository.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: ProfileCategoriesRepository)
class ProfileCategoriesRepositoryImpl implements ProfileCategoriesRepository {
  ProfileCategoriesRepositoryImpl(this._catalogSync);

  final CatalogSyncManager _catalogSync;

  @override
  Future<List<ProfileCategoryModel>> fetchActiveOrdered() {
    return _catalogSync.categories();
  }
}
