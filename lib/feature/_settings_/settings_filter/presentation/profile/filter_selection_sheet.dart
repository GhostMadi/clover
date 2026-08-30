import 'package:clover/core/shared/app_multi_selector.dart';
import 'package:clover/feature/_settings_/settings_filter/data/catalog/filter_catalog.dart';
import 'package:clover/feature/_settings_/settings_filter/data/models/filter_category.dart';
import 'package:flutter/material.dart';

abstract final class FilterSelectionSheet {
  static Future<Set<String>?> show(
    BuildContext context, {
    required List<FilterCategory> categories,
    Set<String> selected = const {},
  }) {
    if (categories.isEmpty) return Future.value(null);

    return AppMultiSelect.showSheet<String>(
      context: context,
      title: selected.isEmpty ? 'Фильтры' : 'Фильтры (${selected.length})',
      groups: FilterCatalog.multiSelectGroups(categories),
      selected: selected,
      searchHint: 'Поиск по фильтрам',
      confirmLabel: 'Применить',
    );
  }
}
