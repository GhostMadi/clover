import 'package:clover/core/storage/domain/repositories/i_app_storage.dart';
import 'package:clover/core/storage/domain/values/file_path_storage_value.dart';

/// JSON helpers for custom models and typed lists.
extension AppStorageJsonExtensions on IAppStorage {
  Future<void> writeObject<T>({
    required String key,
    required T value,
    required Map<String, dynamic> Function(T value) toJson,
  }) {
    return write<Map<String, dynamic>>(key: key, value: toJson(value));
  }

  Future<T?> readObject<T>({
    required String key,
    required T Function(Map<String, dynamic> json) fromJson,
  }) async {
    final json = await read<Map<String, dynamic>>(key: key);
    if (json == null) return null;
    return fromJson(json);
  }

  Future<void> writeList<T>({
    required String key,
    required List<T> value,
    required Object? Function(T item) toJson,
  }) {
    return write<List<dynamic>>(
      key: key,
      value: value.map(toJson).toList(),
    );
  }

  Future<List<T>?> readList<T>({
    required String key,
    required T Function(Object? json) fromJson,
  }) async {
    final raw = await read<List<dynamic>>(key: key);
    if (raw == null) return null;
    return raw.map((item) => fromJson(item)).toList();
  }
}

/// Offline-first file references: store absolute paths, not bytes in Isar.
extension AppStorageFileExtensions on IAppStorage {
  Future<void> writeFilePath({
    required String key,
    required String path,
  }) {
    return write(
      key: key,
      value: FilePathStorageValue(path),
    );
  }

  Future<String?> readFilePath({required String key}) async {
    final stored = await read<FilePathStorageValue>(key: key);
    return stored?.path;
  }
}
