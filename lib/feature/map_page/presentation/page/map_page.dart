import 'package:auto_route/auto_route.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/feature/city/data/models/city_code.dart';
import 'package:clover/feature/city/presentation/widget/city_single_select_field.dart';
import 'package:clover/feature/countries/data/models/country_code.dart';
import 'package:clover/feature/countries/presentation/widget/country_single_select_field.dart';
import 'package:flutter/material.dart';

@RoutePage()
class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  String? _countryCode;
  String? _cityCode;

  void _onCountryChanged(String code) {
    setState(() {
      _countryCode = code;
      _cityCode = null;
    });
  }

  void _onCityChanged(String code) {
    setState(() => _cityCode = code);
  }

  @override
  Widget build(BuildContext context) {
    final country = CountryCode.tryParse(_countryCode);
    final city = country == null
        ? null
        : CityCode.tryParse(countryCode: country.code, cityCode: _cityCode ?? '');

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(title: const Text('Карта')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Text(
              'Страна и город',
              style: AppTextStyle.base(18, color: AppColors.textColor, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 20),
            CountrySingleSelectField(
              label: 'Страна',
              hint: 'Выберите страну',
              value: _countryCode,
              onChanged: _onCountryChanged,
            ),
            const SizedBox(height: 16),
            CitySingleSelectField(
              label: 'Город',
              hint: 'Выберите город',
              countryCode: _countryCode,
              value: _cityCode,
              onChanged: _onCityChanged,
            ),
            const SizedBox(height: 24),
            if (country != null || city != null)
              DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.borderSoft),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Выбрано',
                        style: AppTextStyle.base(13, color: AppColors.subTextColor, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      if (country != null)
                        Text(
                          'Страна: ${country.labelRu} (${country.code})',
                          style: AppTextStyle.base(15, color: AppColors.textColor),
                        ),
                      if (city != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Город: ${city.labelRu} (${city.cityCode})',
                          style: AppTextStyle.base(15, color: AppColors.textColor),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
