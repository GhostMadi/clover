import 'package:clover/feature/post/data/models/post_feed_item.dart';
import 'package:clover/feature/post/data/models/post_marker_summary.dart';
import 'package:clover/feature/post/data/models/post_model.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class EventArchiveRepository {
  /// Архивированные ивенты (маркеры) с превью-постом.
  Future<List<PostFeedItem>> listArchivedEvents(String ownerId);
}

@LazySingleton(as: EventArchiveRepository)
class EventArchiveRepositoryImpl implements EventArchiveRepository {
  EventArchiveRepositoryImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<List<PostFeedItem>> listArchivedEvents(String ownerId) async {
    final uid = ownerId.trim();
    if (uid.isEmpty) return const [];

    final data = await _client
        .from('markers')
        .select('''
          id,
          text_emoji,
          address_primary,
          address_cyrillic,
          country_code,
          city_code,
          event_time,
          end_time,
          status,
          marker_posts(
            is_primary,
            sort_order,
            posts(*, post_media(*))
          )
        ''')
        .eq('owner_id', uid)
        .eq('is_archived', true)
        .order('created_at', ascending: false);

    final items = <PostFeedItem>[];
    for (final raw in data as List<dynamic>) {
      if (raw is! Map) continue;
      final markerMap = Map<String, dynamic>.from(raw);
      final marker = PostMarkerSummary.tryFromJson(markerMap);
      if (marker == null) continue;

      final post = _pickPrimaryPost(markerMap['marker_posts']);
      if (post == null) continue;

      items.add(PostFeedItem(post: post, marker: marker));
    }

    return items;
  }

  PostModel? _pickPrimaryPost(dynamic linksRaw) {
    if (linksRaw is! List || linksRaw.isEmpty) return null;

    final links = <Map<String, dynamic>>[];
    for (final raw in linksRaw) {
      if (raw is Map) links.add(Map<String, dynamic>.from(raw));
    }
    if (links.isEmpty) return null;

    links.sort((a, b) {
      final ap = a['is_primary'] == true ? 0 : 1;
      final bp = b['is_primary'] == true ? 0 : 1;
      if (ap != bp) return ap.compareTo(bp);
      final ao = (a['sort_order'] as num?)?.toInt() ?? 0;
      final bo = (b['sort_order'] as num?)?.toInt() ?? 0;
      return ao.compareTo(bo);
    });

    for (final link in links) {
      final postRaw = link['posts'];
      if (postRaw is! Map) continue;
      return PostModel.fromJson(Map<String, dynamic>.from(postRaw));
    }
    return null;
  }
}
