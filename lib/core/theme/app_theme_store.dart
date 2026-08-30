import 'package:clover/core/storage/domain/repositories/i_app_storage.dart';
import 'package:clover/core/theme/app_theme_mode.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class AppThemeStore {
  AppThemeStore(this._storage);

  final IAppStorage _storage;

  static const _key = 'resource_app_theme_mode';

  Future<AppThemeMode> read() async {
    final raw = await _storage.read<String>(key: _key);
    return AppThemeMode.fromStorage(raw);
  }

  Future<void> write(AppThemeMode mode) {
    return _storage.write<String>(key: _key, value: mode.storageValue);
  }
}
