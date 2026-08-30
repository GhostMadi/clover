import 'package:clover/feature/_catalog_/marker_tags/presentation/widget/multi_marker_tags.dart';
import 'package:flutter/material.dart';

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
      label: 'Теги аккаунта',
      hint: 'Выберите теги',
      sheetTitle: 'Теги аккаунта',
      searchHint: 'Поиск тега',
      values: values,
      onChanged: onChanged,
      enabled: enabled,
    );
  }
}
