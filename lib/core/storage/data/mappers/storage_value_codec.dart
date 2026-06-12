import 'dart:convert';

import 'package:clover/core/storage/data/models/storage_item.dart';
import 'package:clover/core/storage/domain/entities/storage_value_type.dart';
import 'package:clover/core/storage/domain/values/file_path_storage_value.dart';

/// Encodes runtime values into [StorageItem] and decodes them back for [IAppStorage].
abstract final class StorageValueCodec {
  static StorageItem encode<T>({required String key, required T value}) {
    return switch (value) {
      final String v => StorageItem(
        key: key,
        type: StorageValueType.string,
        value: v,
      ),
      final int v => StorageItem(
        key: key,
        type: StorageValueType.int,
        value: v.toString(),
      ),
      final bool v => StorageItem(
        key: key,
        type: StorageValueType.bool,
        value: v.toString(),
      ),
      final double v => StorageItem(
        key: key,
        type: StorageValueType.double,
        value: v.toString(),
      ),
      final FilePathStorageValue v => StorageItem(
        key: key,
        type: StorageValueType.filePath,
        value: v.path,
      ),
      final List<dynamic> v => StorageItem(
        key: key,
        type: StorageValueType.jsonList,
        value: jsonEncode(v),
      ),
      final Map<String, dynamic> v => StorageItem(
        key: key,
        type: StorageValueType.jsonObject,
        value: jsonEncode(v),
      ),
      final Map<dynamic, dynamic> v => StorageItem(
        key: key,
        type: StorageValueType.jsonObject,
        value: jsonEncode(Map<String, dynamic>.from(v)),
      ),
      _ => throw UnsupportedError(
        'Type ${value.runtimeType} is not supported. '
        'Use AppStorageJsonExtensions for custom models.',
      ),
    };
  }

  static T? decode<T>(StorageItem item) {
    final dynamic value = switch (item.type) {
      StorageValueType.string => item.value,
      StorageValueType.int => int.parse(item.value),
      StorageValueType.bool => item.value == 'true',
      StorageValueType.double => double.parse(item.value),
      StorageValueType.filePath => FilePathStorageValue(item.value),
      StorageValueType.jsonObject => Map<String, dynamic>.from(
        jsonDecode(item.value) as Map,
      ),
      StorageValueType.jsonList => List<dynamic>.from(
        jsonDecode(item.value) as List,
      ),
    };
    return value as T?;
  }
}
