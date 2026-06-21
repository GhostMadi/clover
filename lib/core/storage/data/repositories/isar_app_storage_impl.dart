import 'package:clover/core/storage/account_storage_keys.dart';
import 'package:clover/core/storage/data/mappers/storage_value_codec.dart';
import 'package:clover/core/storage/data/models/storage_item.dart';
import 'package:clover/core/storage/domain/repositories/i_app_storage.dart';
import 'package:injectable/injectable.dart';
import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';

@LazySingleton(as: IAppStorage)
class IsarAppStorageImpl implements IAppStorage {
  Isar? _isar;

  static const _dbName = 'clover_app_storage';

  Isar get _db {
    final isar = _isar;
    if (isar == null || !isar.isOpen) {
      throw StateError(
        'AppStorage is not initialized. Call init() before use.',
      );
    }
    return isar;
  }

  @override
  Future<void> init() async {
    if (_isar?.isOpen == true) return;

    final directory = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [StorageItemSchema],
      directory: directory.path,
      name: _dbName,
    );
  }

  @override
  Future<void> write<T>({required String key, required T value}) async {
    final item = StorageValueCodec.encode<T>(key: key, value: value);
    await _db.writeTxn(() => _db.storageItems.put(item));
  }

  @override
  Future<T?> read<T>({required String key}) async {
    final item = await _db.storageItems.filter().keyEqualTo(key).findFirst();
    if (item == null) return null;
    return StorageValueCodec.decode<T>(item);
  }

  @override
  Future<void> delete({required String key}) async {
    await _db.writeTxn(
      () => _db.storageItems.filter().keyEqualTo(key).deleteAll(),
    );
  }

  @override
  Future<void> clearAccountData() async {
    await _db.writeTxn(() async {
      final items = await _db.storageItems.where().findAll();
      final ids = [
        for (final item in items)
          if (AccountStorageKeys.isAccountKey(item.key)) item.id,
      ];
      if (ids.isEmpty) return;
      await _db.storageItems.deleteAll(ids);
    });
  }

  @override
  Future<void> clearAll() async {
    await _db.writeTxn(() => _db.storageItems.clear());
  }
}
