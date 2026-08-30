import 'dart:developer';

import 'package:clover/core/storage/domain/repositories/i_app_storage.dart';
import 'package:clover/core/storage/extensions/app_storage_extensions.dart';
import 'package:clover/feature/_post_/post/data/models/post_model.dart';
import 'package:injectable/injectable.dart';

/// Дисковый кэш ленты постов пользователя (local-first UI).
@lazySingleton
class PostLocalCache {
  PostLocalCache(this._storage);

  final IAppStorage _storage;

  String _feedKey(String userId, {bool onlyWithMarker = false, bool excludeWithMarker = true}) {
    if (onlyWithMarker) return 'post_marker_feed_$userId';
    if (!excludeWithMarker) return 'post_all_feed_$userId';
    return 'post_new_feed_$userId';
  }

  Future<List<PostModel>?> readFeed(
    String userId, {
    bool onlyWithMarker = false,
    bool excludeWithMarker = true,
  }) async {
    final id = userId.trim();
    if (id.isEmpty) return null;

    final list = await _storage.readList<PostModel>(
      key: _feedKey(id, onlyWithMarker: onlyWithMarker, excludeWithMarker: excludeWithMarker),
      fromJson: (json) {
        if (json is! Map) {
          throw FormatException('Expected map');
        }
        return PostModel.fromJson(Map<String, dynamic>.from(json));
      },
    );
    return list;
  }

  Future<void> writeFeed(
    String userId,
    List<PostModel> posts, {
    bool onlyWithMarker = false,
    bool excludeWithMarker = true,
  }) async {
    final id = userId.trim();
    if (id.isEmpty) return;
    await _storage.writeList(
      key: _feedKey(id, onlyWithMarker: onlyWithMarker, excludeWithMarker: excludeWithMarker),
      value: posts,
      toJson: (p) => p.toJson(),
    );
  }

  Future<void> clearFeed(
    String userId, {
    bool onlyWithMarker = false,
    bool excludeWithMarker = true,
  }) async {
    final id = userId.trim();
    if (id.isEmpty) return;
    await _storage.delete(
      key: _feedKey(id, onlyWithMarker: onlyWithMarker, excludeWithMarker: excludeWithMarker),
    );
  }

  /// Убрать пост из всех вариантов дисковой ленты пользователя.
  Future<void> removePostFromUserFeeds(String userId, String postId) async {
    final uid = userId.trim();
    final pid = postId.trim();
    if (uid.isEmpty || pid.isEmpty) return;

    const variants = <({bool onlyWithMarker, bool excludeWithMarker})>[
      (onlyWithMarker: false, excludeWithMarker: true),
      (onlyWithMarker: false, excludeWithMarker: false),
      (onlyWithMarker: true, excludeWithMarker: true),
    ];

    for (final variant in variants) {
      final feed = await readFeed(
        uid,
        onlyWithMarker: variant.onlyWithMarker,
        excludeWithMarker: variant.excludeWithMarker,
      );
      if (feed == null || feed.isEmpty) continue;

      final next = feed.where((post) => post.id != pid).toList(growable: false);
      if (next.length == feed.length) continue;

      if (next.isEmpty) {
        await clearFeed(
          uid,
          onlyWithMarker: variant.onlyWithMarker,
          excludeWithMarker: variant.excludeWithMarker,
        );
      } else {
        await writeFeed(
          uid,
          next,
          onlyWithMarker: variant.onlyWithMarker,
          excludeWithMarker: variant.excludeWithMarker,
        );
      }
    }
  }
}
