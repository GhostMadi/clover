import 'package:clover/core/storage/domain/entities/storage_value_type.dart';
import 'package:isar_community/isar.dart';

part 'storage_item.g.dart';

/// Stable id from a string key (legacy Isar `fastHash` semantics).
int fastHash(String string) {
  var hash = 0xcbf29ce484222325;
  for (var i = 0; i < string.length; i++) {
    hash ^= string.codeUnitAt(i);
    hash *= 0x100000001b3;
  }
  return hash;
}

@collection
class StorageItem {
  StorageItem({required this.key, required this.type, required this.value});

  /// Stable id derived from the storage key (no extra lookup on upsert).
  Id get id => fastHash(key);

  @Index(unique: true, replace: true)
  late String key;

  @enumerated
  late StorageValueType type;

  /// Primitive string form, or JSON / file path depending on [type].
  late String value;
}
