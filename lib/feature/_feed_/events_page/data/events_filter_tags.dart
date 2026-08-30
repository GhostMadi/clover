import 'package:clover/feature/marker_tags/data/models/marker_tag_model.dart';

abstract final class EventsFilterTags {
  static List<String> keysFor(Set<String> tagIds, List<MarkerTagModel> catalog) {
    if (tagIds.isEmpty) return const [];

    final byId = {for (final tag in catalog) tag.id: tag.key};
    return [
      for (final id in tagIds)
        if (byId.containsKey(id)) byId[id]!,
    ];
  }
}
