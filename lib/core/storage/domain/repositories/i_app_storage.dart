/// Universal key-value storage contract for all features.
abstract interface class IAppStorage {
  /// Opens the Isar database and registers [StorageItem] schema.
  Future<void> init();

  Future<void> write<T>({required String key, required T value});

  Future<T?> read<T>({required String key});

  Future<void> delete({required String key});

  /// Удаляет только данные сессии/аккаунта; справочники (`resource_`, `catalog_`) сохраняются.
  Future<void> clearAccountData();

  Future<void> clearAll();
}
