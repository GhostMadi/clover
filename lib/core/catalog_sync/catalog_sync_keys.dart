import 'package:clover/core/catalog_sync/catalog_sync_kind.dart';
import 'package:clover/core/storage/account_storage_keys.dart';

/// Ключи Isar для справочников (`catalog_*` — не удаляются при logout).
abstract final class CatalogSyncKeys {
  CatalogSyncKeys._();

  static const _prefix = 'catalog_';

  static String version(CatalogSyncKind kind) => '$_prefix${kind.name}_version';

  static String data(CatalogSyncKind kind) => '$_prefix${kind.name}_data';

  static bool isCatalogKey(String key) => AccountStorageKeys.resourcePrefixes.any(key.startsWith);
}
