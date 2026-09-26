import 'package:clover/core/extension/context.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_single_selctor.dart';
import 'package:clover/feature/_catalog_/city/data/catalog/cities_catalog.dart';
import 'package:clover/feature/_catalog_/countries/data/models/country_code.dart';
import 'package:clover/feature/_catalog_/shared/catalog_l10n.dart';
import 'package:flutter/material.dart';

/// Одиночный выбор города из [CitiesCatalog] для выбранной страны.
class CitySingleSelectField extends StatelessWidget {
  const CitySingleSelectField({
    super.key,
    this.label,
    required this.hint,
    required this.countryCode,
    required this.value,
    required this.onChanged,
    this.searchHint,
    this.sheetTitle,
    this.disabledHint,
    this.service,
  });

  final String? label;
  final String hint;

  /// Код страны (`kz`, `ru`, …).
  final String? countryCode;
  final String? value;
  final ValueChanged<String> onChanged;
  final String? searchHint;
  final String? sheetTitle;
  final String? disabledHint;
  final AppServiceKind? service;

  List<AppSingleSelectOption<String>> _optionsFor(BuildContext context, String countryCode) {
    final l10n = context.l10n;
    return CitiesCatalog.forCountryCode(countryCode)
        .map((city) => AppSingleSelectOption<String>(value: city.code.cityCode, label: city.code.label(l10n)))
        .toList(growable: false);
  }

  String? _normalize(String? code, List<AppSingleSelectOption<String>> options) {
    final raw = code?.trim();
    if (raw == null || raw.isEmpty) return null;

    for (final option in options) {
      if (option.value.toLowerCase() == raw.toLowerCase()) return option.value;
    }
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final country = CountryCode.tryParse(countryCode);
    if (country == null) {
      return _disabledPlaceholder(context, disabledHint ?? l10n.catalog_city_pick_country_first);
    }

    final options = _optionsFor(context, country.code);

    return AppSingleSelect<String>(
      label: label,
      hint: hint,
      sheetTitle: sheetTitle ?? label ?? l10n.catalog_city_sheet_title,
      searchHint: searchHint ?? l10n.catalog_city_search_hint,
      options: options,
      value: _normalize(value, options),
      onChanged: onChanged,
      service: service,
    );
  }

  Widget _disabledPlaceholder(BuildContext context, String text) {
    return Column(
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: context.colors.fieldBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.colors.fieldBorder),
          ),
          child: Text(
            text,
            style: AppTextStyle.base(16, color: context.colors.subTextColor.withValues(alpha: 0.55), height: 1.25),
          ),
        ),
      ],
    );
  }
}
