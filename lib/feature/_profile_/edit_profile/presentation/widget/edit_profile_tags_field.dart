import 'package:clover/feature/_catalog_/marker_tags/presentation/widget/multi_marker_tags.dart';
import 'package:flutter/material.dart';
import 'package:clover/core/extension/context.dart';

/// Множественный выбор тегов аккаунта из справочника `marker_tags`.
class EditProfileTagsField extends StatelessWidget {
  const EditProfileTagsField({
    super.key,
    required this.values,
    required this.onChanged,
    this.enabled = true,
  });

  final Set<String> values;
  final ValueChanged<Set<String>> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return MultiMarkerTags(
      label: context.l10n.profile_account_tags,
      hint: context.l10n.profile_pick_tags,
      sheetTitle: context.l10n.profile_account_tags,
      searchHint: context.l10n.feed_filter_tags_search,
      values: values,
      onChanged: onChanged,
      enabled: enabled,
    );
  }
}
