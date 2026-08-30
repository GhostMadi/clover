import 'package:clover/core/shared/app_multi_selector.dart';
import 'package:clover/feature/_catalog_/marker_tags/data/models/marker_tag_group_key.dart';
import 'package:clover/feature/_catalog_/marker_tags/data/models/marker_tag_key.dart';

/// Строка справочника `public.marker_tags`.
class MarkerTagModel {
  const MarkerTagModel({
    required this.id,
    required this.key,
    this.groupKey,
    this.createdAt,
  });

  final String id;
  final String key;
  final String? groupKey;
  final DateTime? createdAt;

  MarkerTagKey? get keyEnum => MarkerTagKey.tryParse(key);

  MarkerTagGroupKey? get groupKeyEnum =>
      MarkerTagGroupKey.tryParse(groupKey) ?? keyEnum?.groupKey;

  /// Подпись для UI: из enum, иначе сырой key.
  String get labelRu => keyEnum?.labelRu ?? key;

  /// Заголовок секции: из enum группы, иначе сырой group_key или «Прочее».
  String get groupLabelRu {
    final fromEnum = groupKeyEnum?.labelRu;
    if (fromEnum != null) return fromEnum;
    final raw = groupKey?.trim();
    if (raw != null && raw.isNotEmpty) return raw;
    return 'Прочее';
  }

  factory MarkerTagModel.fromJson(Map<String, dynamic> json) {
    DateTime? createdAt;
    final rawCreated = json['created_at'];
    if (rawCreated is String) {
      createdAt = DateTime.tryParse(rawCreated);
    }

    return MarkerTagModel(
      id: json['id'] as String,
      key: (json['key'] as String?)?.trim() ?? '',
      groupKey: (json['group_key'] as String?)?.trim(),
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'key': key,
    if (groupKey != null) 'group_key': groupKey,
    if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
  };

  /// Группы для [AppMultiSelect] в порядке [MarkerTagGroupKey.sortOrder].
  static List<AppMultiSelectGroup<String>> toMultiSelectGroups(List<MarkerTagModel> tags) {
    if (tags.isEmpty) return const [];

    final buckets = <String, List<MarkerTagModel>>{};
    final bucketOrder = <String>[];
    final bucketSort = <String, int>{};

    for (final tag in tags) {
      final bucketKey = tag.groupKeyEnum?.key ?? tag.groupKey?.trim() ?? '';
      if (!buckets.containsKey(bucketKey)) {
        buckets[bucketKey] = <MarkerTagModel>[];
        bucketOrder.add(bucketKey);
        bucketSort[bucketKey] = tag.groupKeyEnum?.sortOrder ?? 999;
      }
      buckets[bucketKey]!.add(tag);
    }

    bucketOrder.sort((a, b) {
      final byGroup = bucketSort[a]!.compareTo(bucketSort[b]!);
      if (byGroup != 0) return byGroup;
      return a.compareTo(b);
    });

    return bucketOrder.map((bucketKey) {
      final items = List<MarkerTagModel>.of(buckets[bucketKey]!)
        ..sort((a, b) => a.labelRu.compareTo(b.labelRu));

      final title = items.first.groupLabelRu;
      return AppMultiSelectGroup<String>(
        title: title,
        options: items
            .map((tag) => AppMultiSelectOption<String>(value: tag.key, label: tag.labelRu))
            .toList(growable: false),
      );
    }).toList(growable: false);
  }
}
