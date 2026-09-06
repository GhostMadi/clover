import 'package:clover/core/storage/domain/repositories/i_app_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

/// Ярлык «Управление посещаемостью» на профиле (настройка в Сервисы → Посещаемость).
@lazySingleton
class ProfileAttendanceAdminShortcutStore {
  ProfileAttendanceAdminShortcutStore(this._storage);

  final IAppStorage _storage;

  final ValueNotifier<bool> visible = ValueNotifier(false);

  static String _key(String userId) => 'resource_profile_attendance_admin_shortcut_$userId';

  Future<void> load(String userId) async {
    final raw = await _storage.read<bool>(key: _key(userId));
    visible.value = raw ?? false;
  }

  Future<void> setVisible(String userId, bool value) async {
    await _storage.write<bool>(key: _key(userId), value: value);
    visible.value = value;
  }
}
