import 'package:clover/core/storage/domain/repositories/i_app_storage.dart';
import 'package:clover/core/storage/extensions/app_storage_extensions.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_workplace.dart';
import 'package:injectable/injectable.dart';

/// Дисковый кэш списка компаний посещаемости (local-first UI).
@lazySingleton
class AttendanceLocalCache {
  AttendanceLocalCache(this._storage);

  final IAppStorage _storage;

  String _workplacesKey(String userId) => 'attendance_my_workplaces_${userId.trim()}';
  String _foldersKey(String userId) => 'attendance_my_folders_${userId.trim()}';

  Future<List<AttendanceWorkplace>?> readWorkplaces(String userId) {
    return _readList(_workplacesKey(userId), AttendanceWorkplace.fromCacheJson);
  }

  Future<void> writeWorkplaces(String userId, List<AttendanceWorkplace> items) {
    return _writeList(_workplacesKey(userId), items, (e) => e.toCacheJson());
  }

  Future<List<AttendanceFolder>?> readFolders(String userId) {
    return _readList(_foldersKey(userId), AttendanceFolder.fromCacheJson);
  }

  Future<void> writeFolders(String userId, List<AttendanceFolder> items) {
    return _writeList(_foldersKey(userId), items, (e) => e.toCacheJson());
  }

  Future<AttendanceWorkplace?> readWorkplace(String userId, String workplaceId) async {
    final id = workplaceId.trim();
    if (id.isEmpty) return null;
    final list = await readWorkplaces(userId);
    if (list == null) return null;
    for (final w in list) {
      if (w.id == id) return w;
    }
    return null;
  }

  Future<List<T>?> _readList<T>(
    String key,
    T Function(Map<String, dynamic> json) fromJson,
  ) {
    return _storage.readList<T>(
      key: key,
      fromJson: (json) {
        if (json is! Map) throw FormatException('Expected map for $key');
        return fromJson(Map<String, dynamic>.from(json));
      },
    );
  }

  Future<void> _writeList<T>(
    String key,
    List<T> items,
    Map<String, dynamic> Function(T item) toJson,
  ) {
    return _storage.writeList(key: key, value: items, toJson: toJson);
  }
}
