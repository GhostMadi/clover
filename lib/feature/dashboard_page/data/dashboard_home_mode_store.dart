import 'package:clover/core/storage/domain/repositories/i_app_storage.dart';
import 'package:clover/feature/dashboard_page/data/models/dashboard_home_mode.dart';
import 'package:injectable/injectable.dart';

/// Режим первого таба дашборда: лента ивентов или карта.
@lazySingleton
class DashboardHomeModeStore {
  DashboardHomeModeStore(this._storage);

  final IAppStorage _storage;

  static const _key = 'resource_dashboard_home_mode';

  Future<DashboardHomeMode> read() async {
    final raw = await _storage.read<String>(key: _key);
    return DashboardHomeMode.fromStorage(raw);
  }

  Future<void> write(DashboardHomeMode mode) {
    return _storage.write<String>(key: _key, value: mode.storageValue);
  }
}
