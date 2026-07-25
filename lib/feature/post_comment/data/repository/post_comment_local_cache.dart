import 'package:clover/core/storage/domain/repositories/i_app_storage.dart';
import 'package:clover/core/storage/extensions/app_storage_extensions.dart';
import 'package:clover/feature/post_comment/data/models/post_comments_cache_snapshot.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class PostCommentLocalCache {
  PostCommentLocalCache(this._storage);

  final IAppStorage _storage;

  String _key(String userId, String postId) => 'post_comments_${userId.trim()}_${postId.trim()}';

  Future<PostCommentsCacheSnapshot?> read(String userId, String postId) async {
    final uid = userId.trim();
    final pid = postId.trim();
    if (uid.isEmpty || pid.isEmpty) return null;

    return _storage.readObject<PostCommentsCacheSnapshot>(
      key: _key(uid, pid),
      fromJson: PostCommentsCacheSnapshot.fromJson,
    );
  }

  Future<void> write(String userId, String postId, PostCommentsCacheSnapshot snapshot) async {
    final uid = userId.trim();
    final pid = postId.trim();
    if (uid.isEmpty || pid.isEmpty) return;

    await _storage.writeObject(
      key: _key(uid, pid),
      value: snapshot,
      toJson: (value) => value.toJson(),
    );
  }

  Future<void> clear(String userId, String postId) async {
    final uid = userId.trim();
    final pid = postId.trim();
    if (uid.isEmpty || pid.isEmpty) return;
    await _storage.delete(key: _key(uid, pid));
  }
}
