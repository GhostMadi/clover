import 'dart:developer';

import 'package:clover/core/storage/domain/repositories/i_app_storage.dart';
import 'package:clover/core/storage/extensions/app_storage_extensions.dart';
import 'package:clover/feature/post/data/models/post_model.dart';
import 'package:injectable/injectable.dart';

/// Дисковый кэш ленты постов пользователя (local-first UI).
@lazySingleton
class PostLocalCache {
  PostLocalCache(this._storage);

  final IAppStorage _storage;

  String _feedKey(String userId) => 'post_new_feed_$userId';

  Future<List<PostModel>?> readFeed(String userId) async {
    final id = userId.trim();
    if (id.isEmpty) return null;

    final list = await _storage.readList<PostModel>(
      key: _feedKey(id),
      fromJson: (json) {
        if (json is! Map) {
          throw FormatException('Expected map');
        }
        return PostModel.fromJson(Map<String, dynamic>.from(json));
      },
    );
    return list;
  }

  Future<void> writeFeed(String userId, List<PostModel> posts) async {
    final id = userId.trim();
    if (id.isEmpty) return;
    await _storage.writeList(key: _feedKey(id), value: posts, toJson: (p) => p.toJson());
  }

  Future<void> clearFeed(String userId) async {
    final id = userId.trim();
    if (id.isEmpty) return;
    await _storage.delete(key: _feedKey(id));
  }
}
