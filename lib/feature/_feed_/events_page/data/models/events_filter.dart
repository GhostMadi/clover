import 'package:clover/feature/_feed_/events_page/data/models/events_content_kind.dart';

class EventsFilter {
  const EventsFilter({
    this.contentKind = EventsContentKind.all,
    this.dateFrom,
    this.dateTo,
    this.countryCode,
    this.cityCode,
    this.emoji,
    this.tagIds = const {},
  });

  final EventsContentKind contentKind;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final String? countryCode;
  final String? cityCode;
  final String? emoji;

  /// Выбранные ключи тегов (`marker_tags.key`, как enum).
  final Set<String> tagIds;

  static const defaults = EventsFilter();

  bool get hasSelection {
    if (contentKind == EventsContentKind.all) return true;
    return dateFrom != null || dateTo != null || _isSet(emoji) || tagIds.isNotEmpty;
  }

  EventsFilter copyWith({
    EventsContentKind? contentKind,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? countryCode,
    String? cityCode,
    String? emoji,
    Set<String>? tagIds,
    bool clearDateFrom = false,
    bool clearDateTo = false,
    bool clearCity = false,
    bool clearEmoji = false,
    bool clearTagIds = false,
  }) {
    return EventsFilter(
      contentKind: contentKind ?? this.contentKind,
      dateFrom: clearDateFrom ? null : (dateFrom ?? this.dateFrom),
      dateTo: clearDateTo ? null : (dateTo ?? this.dateTo),
      countryCode: countryCode ?? this.countryCode,
      cityCode: clearCity ? null : (cityCode ?? this.cityCode),
      emoji: clearEmoji ? null : (emoji ?? this.emoji),
      tagIds: clearTagIds ? const {} : (tagIds ?? this.tagIds),
    );
  }

  static bool _isSet(String? value) {
    final raw = value?.trim();
    return raw != null && raw.isNotEmpty;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EventsFilter &&
        other.contentKind == contentKind &&
        other.dateFrom == dateFrom &&
        other.dateTo == dateTo &&
        other.countryCode == countryCode &&
        other.cityCode == cityCode &&
        other.emoji == emoji &&
        _sameTags(other.tagIds, tagIds);
  }

  @override
  int get hashCode => Object.hash(
        contentKind,
        dateFrom,
        dateTo,
        countryCode,
        cityCode,
        emoji,
        Object.hashAllUnordered(tagIds),
      );

  static bool _sameTags(Set<String> a, Set<String> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    return a.containsAll(b);
  }
}
