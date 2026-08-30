import 'package:clover/feature/_feed_/events_page/data/models/events_content_kind.dart';
import 'package:clover/feature/_feed_/events_page/data/models/events_filter.dart';
import 'package:clover/feature/_post_/post/data/models/post_feed_item.dart';

abstract final class EventsFeedFilter {
  static List<PostFeedItem> apply(List<PostFeedItem> items, EventsFilter filter) {
    return [
      for (final item in items)
        if (_matches(item, filter)) item,
    ];
  }

  static bool _matches(PostFeedItem item, EventsFilter filter) {
    final isEvent = item.marker != null || item.post.hasMarker;
    if (filter.contentKind == EventsContentKind.eventsOnly && !isEvent) {
      return false;
    }

    final marker = item.marker;
    if (_isSet(filter.countryCode) && marker?.countryCode?.trim().toLowerCase() != filter.countryCode!.trim().toLowerCase()) {
      return false;
    }
    if (_isSet(filter.cityCode) && marker?.cityCode?.trim().toLowerCase() != filter.cityCode!.trim().toLowerCase()) {
      return false;
    }
    if (_isSet(filter.emoji) && marker?.textEmoji.trim() != filter.emoji!.trim()) {
      return false;
    }

    if (filter.dateFrom != null || filter.dateTo != null) {
      final eventTime = marker?.eventTime?.toLocal();
      if (eventTime == null) return filter.contentKind == EventsContentKind.all;

      final day = _dayOnly(eventTime);
      if (filter.dateFrom != null && day.isBefore(_dayOnly(filter.dateFrom!))) return false;
      if (filter.dateTo != null && day.isAfter(_dayOnly(filter.dateTo!))) return false;
    }

    if (filter.tagIds.isNotEmpty) {
      if (marker == null) return false;
      final markerTagIds = marker.tags.map((tag) => tag.id).toSet();
      if (!filter.tagIds.any(markerTagIds.contains)) return false;
    }

    return true;
  }

  static DateTime _dayOnly(DateTime date) => DateTime(date.year, date.month, date.day);

  static bool _isSet(String? value) {
    final raw = value?.trim();
    return raw != null && raw.isNotEmpty;
  }
}
