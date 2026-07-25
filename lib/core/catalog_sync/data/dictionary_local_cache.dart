import 'package:clover/core/catalog_sync/catalog_sync_kind.dart';
import 'package:clover/core/catalog_sync/catalog_sync_keys.dart';
import 'package:clover/core/storage/domain/repositories/i_app_storage.dart';
import 'package:clover/core/storage/extensions/app_storage_extensions.dart';
import 'package:injectable/injectable.dart';

/// Локальное хранение массивов справочников и их версий.
@lazySingleton
class DictionaryLocalCache {
  DictionaryLocalCache(this._storage);

  final IAppStorage _storage;

  Future<String?> readVersion(CatalogSyncKind kind) {
    return _storage.read<String>(key: CatalogSyncKeys.version(kind));
  }

  Future<void> writeVersion(CatalogSyncKind kind, String version) {
    return _storage.write(key: CatalogSyncKeys.version(kind), value: version.trim());
  }

  Future<List<T>?> readList<T>({
    required CatalogSyncKind kind,
    required T Function(Map<String, dynamic> json) fromJson,
  }) {
    return _storage.readList<T>(
      key: CatalogSyncKeys.data(kind),
      fromJson: (json) {
        if (json is! Map) {
          throw FormatException('Expected map for ${kind.name}');
        }
        return fromJson(Map<String, dynamic>.from(json));
      },
    );
  }

  Future<void> writeList<T>({
    required CatalogSyncKind kind,
    required List<T> items,
    required Map<String, dynamic> Function(T item) toJson,
  }) {
    return _storage.writeList<T>(
      key: CatalogSyncKeys.data(kind),
      value: items,
      toJson: (item) => toJson(item),
    );
  }

  Future<void> clearKind(CatalogSyncKind kind) async {
    await _storage.delete(key: CatalogSyncKeys.version(kind));
    await _storage.delete(key: CatalogSyncKeys.data(kind));
  }

  Future<void> clearAll() async {
    for (final kind in CatalogSyncKind.values) {
      await clearKind(kind);
    }
  }
}
