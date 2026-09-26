import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/shared/app_multi_selector.dart';
import 'package:clover/feature/_settings_/settings_filter/data/catalog/filter_catalog.dart';
import 'package:clover/feature/_settings_/settings_filter/data/models/filter_category.dart';
import 'package:flutter/material.dart';
import 'package:clover/core/extension/context.dart';

abstract final class FilterSelectionSheet {
  static Future<Set<String>?> show(
    BuildContext context, {
    required List<FilterCategory> categories,
    Set<String> selected = const {},
  }) {
    if (categories.isEmpty) return Future.value(null);

    return AppMultiSelect.showSheet<String>(
      context: context,
      title: selected.isEmpty ? context.l10n.common_filters : context.l10n.settings_filters_count(selected.length),
      groups: FilterCatalog.multiSelectGroups(categories),
      selected: selected,
      searchHint: context.l10n.settings_filters_search,
      confirmLabel: context.l10n.common_apply,
      service: kResourcesService,
    );
  }
}
