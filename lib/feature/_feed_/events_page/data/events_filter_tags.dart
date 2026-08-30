import 'package:clover/feature/_catalog_/marker_tags/data/models/marker_tag_model.dart';

abstract final class EventsFilterTags {
  /// Проверяет ключи тегов против enum-справочника.
  static List<String> keysFor(Set<String> tagKeys, List<MarkerTagModel> catalog) {
    if (tagKeys.isEmpty) return const [];

    final known = {for (final tag in catalog) tag.key: tag.key};
    return [
      for (final key in tagKeys)
        if (known.containsKey(key)) key,
    ];
  }
}
