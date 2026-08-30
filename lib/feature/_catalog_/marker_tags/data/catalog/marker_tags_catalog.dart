import 'package:clover/feature/_catalog_/marker_tags/data/models/marker_tag_key.dart';
import 'package:clover/feature/_catalog_/marker_tags/data/models/marker_tag_model.dart';

/// Справочник тегов (данные как в `public.marker_tags.key` + группы).
///
/// В UI значение селектора = [MarkerTagKey.key] (как `country_code` у стран).
abstract final class MarkerTagsCatalog {
  static List<MarkerTagModel> get all {
    return MarkerTagKey.values
        .map(
          (tag) => MarkerTagModel(
            id: tag.key,
            key: tag.key,
            groupKey: tag.groupKey.key,
          ),
        )
        .toList(growable: false);
  }
}
