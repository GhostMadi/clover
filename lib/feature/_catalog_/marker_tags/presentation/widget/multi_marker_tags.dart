import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_bottom_sheet.dart';
import 'package:clover/core/shared/app_multi_selector.dart';
import 'package:clover/feature/_catalog_/marker_tags/data/catalog/marker_tags_catalog.dart';
import 'package:clover/feature/_catalog_/marker_tags/data/models/marker_tag_group_key.dart';
import 'package:clover/feature/_catalog_/marker_tags/data/models/marker_tag_model.dart';
import 'package:clover/feature/_catalog_/marker_tags/presentation/widget/marker_tag_chip.dart';
import 'package:flutter/material.dart';

/// Множественный выбор тегов из enum-справочника [MarkerTagsCatalog].
class MultiMarkerTags extends StatelessWidget {
  const MultiMarkerTags({
    super.key,
    this.label,
    required this.hint,
    required this.values,
    required this.onChanged,
    this.searchHint = 'Поиск тега',
    this.sheetTitle,
    this.enabled = true,
    this.excludeGroupKeys = const {},
  });

  final String? label;
  final String hint;

  /// Ключи выбранных тегов (`marker_tags.key`).
  final Set<String> values;
  final ValueChanged<Set<String>> onChanged;

  final String searchHint;
  final String? sheetTitle;
  final bool enabled;
  final Set<MarkerTagGroupKey> excludeGroupKeys;

  static const double _fieldRadius = 12;

  List<MarkerTagModel> get _tags {
    final items = MarkerTagsCatalog.all;
    if (excludeGroupKeys.isEmpty) return items;

    return items
        .where((tag) {
          final group = tag.groupKeyEnum;
          return group == null || !excludeGroupKeys.contains(group);
        })
        .toList(growable: false);
  }

  Set<String> _normalizeValues(List<MarkerTagModel> tags) {
    if (values.isEmpty || tags.isEmpty) return const {};

    final knownKeys = tags.map((tag) => tag.key).toSet();
    return values.where(knownKeys.contains).toSet();
  }

  List<MarkerTagModel> _selectedTags(List<MarkerTagModel> tags, Set<String> selected) {
    if (selected.isEmpty) return const [];
    return [
      for (final tag in tags)
        if (selected.contains(tag.key)) tag,
    ];
  }

  Future<void> _openSheet(BuildContext context, List<MarkerTagModel> tags) async {
    if (tags.isEmpty || !enabled) return;

    final groups = MarkerTagModel.toMultiSelectGroups(tags);
    final picked = await AppBottomSheet.show<Set<String>>(
      context: context,
      title: sheetTitle ?? label ?? 'Теги маркера',
      upperCaseTitle: false,
      showCloseButton: true,
      contentBottomSpacing: 0,
      expandBody: true,
      content: AppMultiSelectSheetContent<String>(
        searchHint: searchHint,
        groups: groups,
        options: const [],
        selected: _normalizeValues(tags),
        confirmLabel: 'Готово',
      ),
    );

    if (picked == null) return;
    onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final tags = _tags;
    final emptyHint = tags.isEmpty ? 'Нет доступных тегов' : hint;
    final selected = _normalizeValues(tags);
    final selectedTags = _selectedTags(tags, selected);
    final hasValue = selectedTags.isNotEmpty;
    final canOpen = tags.isNotEmpty && enabled;

    final field = Material(
      color: context.colors.fieldBackground,
      borderRadius: BorderRadius.circular(_fieldRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(_fieldRadius),
        onTap: canOpen ? () => _openSheet(context, tags) : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_fieldRadius),
            border: Border.all(color: context.colors.fieldBorder),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: hasValue
                    ? Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final tag in selectedTags) MarkerTagChip(tag: tag),
                        ],
                      )
                    : Text(
                        emptyHint,
                        style: AppTextStyle.base(
                          16,
                          color: context.colors.subTextColor.withValues(alpha: 0.65),
                          height: 1.25,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(
                  AppIcons.arrowDown.icon,
                  color: context.colors.subTextColor.withValues(alpha: 0.55),
                  size: 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return AbsorbPointer(
      absorbing: !enabled,
      child: Opacity(
        opacity: enabled ? 1 : 0.55,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (label != null) ...[
              Text(
                label!,
                style: AppTextStyle.base(14, color: context.colors.subTextColor, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
            ],
            field,
          ],
        ),
      ),
    );
  }
}
