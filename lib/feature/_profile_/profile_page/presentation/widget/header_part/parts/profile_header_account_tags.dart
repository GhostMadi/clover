import 'package:clover/feature/_catalog_/marker_tags/data/models/marker_tag_model.dart';
import 'package:clover/feature/_catalog_/marker_tags/presentation/widget/marker_tag_chip.dart';
import 'package:flutter/material.dart';

/// Витринные теги под идентичностью в шапке профиля.
///
/// Силовые (`admin` / `worker`) **не** показываем: они уже живут кнопками
/// сервисов на своём профиле и CTA у гостя — чипы только мешают.
class ProfileHeaderAccountTags extends StatelessWidget {
  const ProfileHeaderAccountTags({super.key, required this.tags});

  final List<MarkerTagModel> tags;

  @override
  Widget build(BuildContext context) {
    final showcase = [
      for (final tag in tags)
        if (!(tag.keyEnum?.isServicePower ?? false)) tag,
    ];
    if (showcase.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final tag in showcase) MarkerTagChip(tag: tag),
      ],
    );
  }
}
