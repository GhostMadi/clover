import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/feature/_catalog_/marker_tags/data/models/marker_tag_model.dart';
import 'package:flutter/material.dart';

/// Теги аккаунта под блоком идентичности в шапке профиля.
class ProfileHeaderAccountTags extends StatelessWidget {
  const ProfileHeaderAccountTags({super.key, required this.tags});

  final List<MarkerTagModel> tags;

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final tag in tags)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: context.colors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '#${tag.labelRu.toLowerCase()}',
              style: AppTextStyle.base(11, fontWeight: FontWeight.w700, color: context.colors.primary),
            ),
          ),
      ],
    );
  }
}
