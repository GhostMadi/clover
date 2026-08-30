import 'package:clover/core/storage/domain/repositories/i_app_storage.dart';
import 'package:clover/core/storage/extensions/app_storage_extensions.dart';
import 'package:clover/feature/_post_/post_share/data/models/post_share_recipient.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class PostShareLocalCache {
  PostShareLocalCache(this._storage);

  final IAppStorage _storage;

  String _followingKey(String userId) => 'post_share_following_${userId.trim()}';

  String _frequentKey(String userId) => 'post_share_frequent_${userId.trim()}';

  Future<List<PostShareRecipient>?> readFollowing(String userId) {
    return _readList(_followingKey(userId));
  }

  Future<List<PostShareRecipient>?> readFrequent(String userId) {
    return _readList(_frequentKey(userId));
  }

  Future<void> writeFollowing(String userId, List<PostShareRecipient> items) {
    return _writeList(_followingKey(userId), items);
  }

  Future<void> writeFrequent(String userId, List<PostShareRecipient> items) {
    return _writeList(_frequentKey(userId), items);
  }

  Future<List<PostShareRecipient>?> _readList(String key) {
    return _storage.readList<PostShareRecipient>(
      key: key,
      fromJson: (json) {
        if (json is! Map) throw FormatException('Expected map');
        return PostShareRecipient.fromJson(Map<String, dynamic>.from(json));
      },
    );
  }

  Future<void> _writeList(String key, List<PostShareRecipient> items) {
    return _storage.writeList(
      key: key,
      value: items,
      toJson: (item) => item.toJson(),
    );
  }
}
