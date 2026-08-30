import 'package:clover/feature/_post_/post/data/models/post_model.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class SavedPostsRepository {
  Future<List<PostModel>> listSavedPosts({int limit = 24, int offset = 0});
}

@LazySingleton(as: SavedPostsRepository)
class SavedPostsRepositoryImpl implements SavedPostsRepository {
  SavedPostsRepositoryImpl(this._client);

  final SupabaseClient _client;

  static const _pageSizeCap = 100;

  @override
  Future<List<PostModel>> listSavedPosts({int limit = 24, int offset = 0}) async {
    final safeLimit = limit.clamp(1, _pageSizeCap);
    final safeOffset = offset < 0 ? 0 : offset;

    final res = await _client.rpc(
      'list_my_saved_posts',
      params: <String, dynamic>{
        'p_limit': safeLimit,
        'p_offset': safeOffset,
      },
    );

    if (res is! List) return const [];

    final items = <PostModel>[];
    for (final row in res) {
      if (row is! Map) continue;
      final postRaw = row['post'];
      if (postRaw is! Map) continue;
      items.add(PostModel.fromJson(Map<String, dynamic>.from(postRaw)));
    }
    return items;
  }
}
