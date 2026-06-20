import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_single_selctor.dart';
import 'package:clover/feature/city/data/catalog/cities_catalog.dart';
import 'package:clover/feature/countries/data/models/country_code.dart';
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
    this.searchHint = 'Поиск города',
    this.sheetTitle,
    this.disabledHint = 'Сначала выберите страну',
  });

  final String? label;
  final String hint;

  /// Код страны (`kz`, `ru`, …).
  final String? countryCode;
  final String? value;
  final ValueChanged<String> onChanged;
  final String searchHint;
  final String? sheetTitle;
  final String disabledHint;

  List<AppSingleSelectOption<String>> _optionsFor(String countryCode) {
    return CitiesCatalog.forCountryCode(countryCode)
        .map((city) => AppSingleSelectOption<String>(value: city.code.cityCode, label: city.code.labelRu))
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
    final country = CountryCode.tryParse(countryCode);
    if (country == null) {
      return _disabledPlaceholder(context, disabledHint);
    }

    final options = _optionsFor(country.code);

    return AppSingleSelect<String>(
      label: label,
      hint: hint,
      sheetTitle: sheetTitle ?? label ?? 'Город',
      searchHint: searchHint,
      options: options,
      value: _normalize(value, options),
      onChanged: onChanged,
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
            style: AppTextStyle.base(14, color: AppColors.subTextColor, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
        ],
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.fieldBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.fieldBorder),
          ),
          child: Text(
            text,
            style: AppTextStyle.base(16, color: AppColors.subTextColor.withValues(alpha: 0.55), height: 1.25),
          ),
        ),
      ],
    );
  }
}
