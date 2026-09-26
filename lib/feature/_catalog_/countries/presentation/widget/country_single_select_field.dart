import 'package:clover/core/extension/context.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/shared/app_single_selctor.dart';
import 'package:clover/feature/_catalog_/countries/data/catalog/countries_catalog.dart';
import 'package:clover/feature/_catalog_/countries/data/models/country_code.dart';
import 'package:clover/feature/_catalog_/shared/catalog_l10n.dart';
import 'package:flutter/material.dart';

/// Одиночный выбор страны из [CountriesCatalog].
class CountrySingleSelectField extends StatelessWidget {
  const CountrySingleSelectField({
    super.key,
    this.label,
    required this.hint,
    required this.value,
    required this.onChanged,
    this.searchHint,
    this.sheetTitle,
    this.service,
  });

  final String? label;
  final String hint;

  /// Код страны (`kz`, `ru`, …).
  final String? value;
  final ValueChanged<String> onChanged;
  final String? searchHint;
  final String? sheetTitle;
  final AppServiceKind? service;

  List<AppSingleSelectOption<String>> _options(BuildContext context) {
    final l10n = context.l10n;
    return CountriesCatalog.countries
        .map(
          (country) => AppSingleSelectOption<String>(
            value: country.code.code,
            label: country.code.label(l10n),
          ),
        )
        .toList(growable: false);
  }

  String? _normalize(String? code) {
    final parsed = CountryCode.tryParse(code);
    return parsed?.code;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppSingleSelect<String>(
      label: label,
      hint: hint,
      sheetTitle: sheetTitle ?? label ?? l10n.catalog_country_sheet_title,
      searchHint: searchHint ?? l10n.catalog_country_search_hint,
      options: _options(context),
      value: _normalize(value),
      onChanged: onChanged,
      service: service,
    );
  }
}
