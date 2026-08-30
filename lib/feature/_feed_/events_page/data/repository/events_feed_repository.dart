import 'package:clover/feature/events_page/data/events_filter_tags.dart';
import 'package:clover/feature/events_page/data/models/events_content_kind.dart';
import 'package:clover/feature/events_page/data/models/events_feed_page.dart';
import 'package:clover/feature/events_page/data/models/events_filter.dart';
import 'package:clover/feature/marker_tags/data/repository/marker_tags_repository.dart';
import 'package:clover/feature/post/data/models/post_feed_item.dart';
import 'package:clover/feature/post/data/repository/post_feed_enriched_parser.dart';
import 'package:clover/feature/post/data/repository/post_repository.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class EventsFeedRepository {
  Future<EventsFeedPage> listFeed({
    required EventsFilter filter,
    int limit = 24,
    PostFeedItem? cursorItem,
  });
}

@LazySingleton(as: EventsFeedRepository)
class EventsFeedRepositoryImpl implements EventsFeedRepository {
  EventsFeedRepositoryImpl(this._client, this._postRepository, this._markerTagsRepository);

  final SupabaseClient _client;
  final PostRepository _postRepository;
  final MarkerTagsRepository _markerTagsRepository;

  static const _pageSizeCap = 100;

  @override
  Future<EventsFeedPage> listFeed({
    required EventsFilter filter,
    int limit = 24,
    PostFeedItem? cursorItem,
  }) async {
    final safeLimit = limit.clamp(1, _pageSizeCap);
    final pArgs = await _buildArgs(filter: filter, limit: safeLimit, cursorItem: cursorItem);

    final res = await _client.rpc(
      'list_events_feed_enriched_cursor',
      params: <String, dynamic>{'p_args': pArgs},
    );

    final onlyWithMarker = filter.contentKind == EventsContentKind.eventsOnly ? true : null;
    final items = PostFeedEnrichedParser.parse(
      res,
      onlyWithMarker: onlyWithMarker,
      onItemParsed: _postRepository.cacheFeedItem,
    );

    return EventsFeedPage(
      items: items,
      hasMore: items.length >= safeLimit,
    );
  }

  Future<Map<String, dynamic>> _buildArgs({
    required EventsFilter filter,
    required int limit,
    PostFeedItem? cursorItem,
  }) async {
    final args = <String, dynamic>{
      'p_limit': limit,
      'p_content_kind': filter.contentKind == EventsContentKind.all ? 'all' : 'events_only',
      'p_at_time': DateTime.now().toUtc().toIso8601String(),
    };

    final country = filter.countryCode?.trim();
    if (country != null && country.isNotEmpty) {
      args['p_country_code'] = country;
    }

    final city = filter.cityCode?.trim();
    if (city != null && city.isNotEmpty) {
      args['p_city_code'] = city;
    }

    final emoji = filter.emoji?.trim();
    if (emoji != null && emoji.isNotEmpty) {
      args['p_emoji'] = emoji;
    }

    if (filter.dateFrom != null) {
      args['p_date_from'] = _dateOnly(filter.dateFrom!);
    }
    if (filter.dateTo != null) {
      args['p_date_to'] = _dateOnly(filter.dateTo!);
    }

    if (filter.tagIds.isNotEmpty) {
      final tagKeys = EventsFilterTags.keysFor(filter.tagIds, await _markerTagsRepository.listAll());
      if (tagKeys.isNotEmpty) {
        args['p_tag_keys'] = tagKeys;
      }
    }

    if (cursorItem != null) {
      if (filter.contentKind == EventsContentKind.all) {
        args['p_cursor_created_at'] = cursorItem.post.createdAt.toUtc().toIso8601String();
      } else {
        final eventTime = cursorItem.marker?.eventTime ?? cursorItem.post.createdAt;
        args['p_cursor_event_time'] = eventTime.toUtc().toIso8601String();
      }
      args['p_cursor_id'] = cursorItem.post.id;
    }

    return args;
  }

  static String _dateOnly(DateTime date) {
    final local = date.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
