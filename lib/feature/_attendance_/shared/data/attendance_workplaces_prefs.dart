import 'package:clover/core/session/app_session.dart';
import 'package:clover/core/storage/domain/repositories/i_app_storage.dart';
import 'package:injectable/injectable.dart';

/// Last selected attendance company (mirror booking last point).
@lazySingleton
class AttendanceWorkplacesPrefs {
  AttendanceWorkplacesPrefs(this._storage, this._session);

  final IAppStorage _storage;
  final AppSession _session;

  String? _key() {
    final uid = _session.userId?.trim();
    if (uid == null || uid.isEmpty) return null;
    return 'attendance_last_workplace_$uid';
  }

  Future<String?> readLastWorkplaceId() async {
    final key = _key();
    if (key == null) return null;
    final raw = await _storage.read<String>(key: key);
    final id = raw?.trim();
    if (id == null || id.isEmpty) return null;
    return id;
  }

  Future<void> writeLastWorkplaceId(String workplaceId) async {
    final key = _key();
    if (key == null) return;
    final id = workplaceId.trim();
    if (id.isEmpty) return;
    await _storage.write<String>(key: key, value: id);
  }
}
