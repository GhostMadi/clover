import 'package:clover/feature/post/data/models/post_model.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class PostArchiveRepository {
  /// Архивированные публикации (без привязки к маркеру / ивенту).
  Future<List<PostModel>> listArchivedPublications(String userId);
}

@LazySingleton(as: PostArchiveRepository)
class PostArchiveRepositoryImpl implements PostArchiveRepository {
  PostArchiveRepositoryImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<List<PostModel>> listArchivedPublications(String userId) async {
    final uid = userId.trim();
    if (uid.isEmpty) return const [];

    final data = await _client
        .from('posts')
        .select('*, post_media(*)')
        .eq('user_id', uid)
        .eq('is_archived', true)
        .isFilter('deleted_at', null)
        .order('updated_at', ascending: false);

    final markerPostIds = await _markerLinkedPostIds(uid);
    final list = data as List<dynamic>;
    final items = <PostModel>[];

    for (final raw in list) {
      if (raw is! Map) continue;
      final post = PostModel.fromJson(Map<String, dynamic>.from(raw));
      if (markerPostIds.contains(post.id)) continue;
      items.add(post);
    }

    return items;
  }

  Future<Set<String>> _markerLinkedPostIds(String userId) async {
    final data = await _client.from('marker_posts').select('post_id, posts!inner(user_id)').eq('posts.user_id', userId);

    final ids = <String>{};
    for (final raw in data as List<dynamic>) {
      if (raw is! Map) continue;
      final id = (raw['post_id'] as String?)?.trim();
      if (id != null && id.isNotEmpty) ids.add(id);
    }
    return ids;
  }
}
