import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_bottom_sheet.dart';
import 'package:clover/core/shared/app_multi_selector.dart';
import 'package:clover/feature/_catalog_/marker_tags/data/catalog/marker_tags_catalog.dart';
import 'package:clover/feature/_catalog_/marker_tags/data/models/marker_tag_group_key.dart';
import 'package:clover/feature/_catalog_/marker_tags/data/models/marker_tag_model.dart';
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

  String? _selectedDisplay(List<MarkerTagModel> tags, Set<String> selected) {
    if (selected.isEmpty) return null;

    final labels = <String>[];
    for (final tag in tags) {
      if (selected.contains(tag.key)) labels.add(tag.labelRu);
    }
    if (labels.isEmpty) return null;
    return labels.join(', ');
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
    final display = _selectedDisplay(tags, selected);
    final hasValue = display != null && display.isNotEmpty;
    final canOpen = tags.isNotEmpty && enabled;

    final field = Material(
      color: AppColors.fieldBackground,
      borderRadius: BorderRadius.circular(_fieldRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(_fieldRadius),
        onTap: canOpen ? () => _openSheet(context, tags) : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_fieldRadius),
            border: Border.all(color: AppColors.fieldBorder),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  hasValue ? display : emptyHint,
                  style: AppTextStyle.base(
                    16,
                    color: hasValue ? AppColors.textColor : AppColors.subTextColor.withValues(alpha: 0.65),
                    height: 1.25,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                AppIcons.arrowDown.icon,
                color: AppColors.subTextColor.withValues(alpha: 0.55),
                size: 24,
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
                style: AppTextStyle.base(14, color: AppColors.subTextColor, fontWeight: FontWeight.w600),
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
