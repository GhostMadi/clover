import 'package:clover/core/shared/app_single_selctor.dart';
import 'package:clover/feature/_catalog_/countries/data/catalog/countries_catalog.dart';
import 'package:clover/feature/_catalog_/countries/data/models/country_code.dart';
import 'package:flutter/material.dart';

/// Одиночный выбор страны из [CountriesCatalog].
class CountrySingleSelectField extends StatelessWidget {
  const CountrySingleSelectField({
    super.key,
    this.label,
    required this.hint,
    required this.value,
    required this.onChanged,
    this.searchHint = 'Поиск страны',
    this.sheetTitle,
  });

  final String? label;
  final String hint;

  /// Код страны (`kz`, `ru`, …).
  final String? value;
  final ValueChanged<String> onChanged;
  final String searchHint;
  final String? sheetTitle;

  static List<AppSingleSelectOption<String>> get _options {
    return CountriesCatalog.countries
        .map(
          (country) => AppSingleSelectOption<String>(value: country.code.code, label: country.code.labelRu),
        )
        .toList(growable: false);
  }

  String? _normalize(String? code) {
    final parsed = CountryCode.tryParse(code);
    return parsed?.code;
  }

  @override
  Widget build(BuildContext context) {
    return AppSingleSelect<String>(
      label: label,
      hint: hint,
      sheetTitle: sheetTitle ?? label ?? 'Страна',
      searchHint: searchHint,
      options: _options,
      value: _normalize(value),
      onChanged: onChanged,
    );
  }
}
