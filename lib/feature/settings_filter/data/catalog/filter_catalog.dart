import 'package:clover/core/shared/app_multi_selector.dart';
import 'package:clover/feature/settings_filter/data/models/filter_category.dart';

/// Каталог фильтров (пока mock; позже — из настроек / API).
abstract final class FilterCatalog {
  static const List<FilterCategory> seed = [
    FilterCategory(id: 'size', name: 'Размер', values: ['XS', 'S', 'M', 'L', 'XL']),
    FilterCategory(id: 'color', name: 'Цвет', values: ['Черный', 'Белый', 'Красный']),
    FilterCategory(id: 'brand', name: 'Бренд', values: ['Nike', 'Adidas', 'Puma']),
  ];

  static List<AppMultiSelectGroup<String>> multiSelectGroups(List<FilterCategory> categories) {
    return [
      for (final category in categories)
        AppMultiSelectGroup(
          title: category.name,
          options: [
            for (final value in category.values)
              AppMultiSelectOption(
                value: selectionValue(category.id, value),
                label: value,
              ),
          ],
        ),
    ];
  }

  static String selectionValue(String categoryId, String label) => '$categoryId:$label';

  static String selectionLabel(String value) {
    final parts = value.split(':');
    if (parts.length < 2) return value;
    return parts.sublist(1).join(':');
  }

  static List<String> selectionLabels(Set<String> values) {
    return values.map(selectionLabel).toList(growable: false);
  }
}
