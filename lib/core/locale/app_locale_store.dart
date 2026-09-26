import 'package:clover/core/locale/app_locale.dart';
import 'package:clover/core/storage/domain/repositories/i_app_storage.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class AppLocaleStore {
  AppLocaleStore(this._storage);

  final IAppStorage _storage;

  static const _key = 'resource_app_locale';

  Future<AppLocale?> read() async {
    final raw = await _storage.read<String>(key: _key);
    if (raw == null || raw.trim().isEmpty) return null;
    return AppLocale.fromStorage(raw);
  }

  Future<void> write(AppLocale locale) {
    return _storage.write<String>(key: _key, value: locale.languageCode);
  }
}
