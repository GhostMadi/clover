import 'package:clover/feature/_post_/post/data/models/post_model.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class PostArchiveRepository {
  /// Все архивированные посты пользователя (включая связанные с маркером).
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
        .order('created_at', ascending: false);

    final list = data as List<dynamic>;
    final items = <PostModel>[];

    for (final raw in list) {
      if (raw is! Map) continue;
      items.add(PostModel.fromJson(Map<String, dynamic>.from(raw)));
    }

    return items;
  }
}
