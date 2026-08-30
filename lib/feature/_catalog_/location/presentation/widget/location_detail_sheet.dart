import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_bottom_sheet.dart';
import 'package:clover/core/shared/app_button.dart';
import 'package:clover/core/shared/app_dialog.dart';
import 'package:clover/core/shared/app_field.dart';
import 'package:clover/core/shared/app_field/english_address_input_formatter.dart';
import 'package:clover/core/shared/app_switch.dart';
import 'package:clover/core/shared/app_text_button.dart';
import 'package:clover/feature/_catalog_/city/presentation/widget/city_single_select_field.dart';
import 'package:clover/feature/_catalog_/countries/presentation/widget/country_single_select_field.dart';
import 'package:clover/feature/_catalog_/location/data/models/location_model.dart';
import 'package:clover/feature/_catalog_/location/data/repository/location_repository.dart';
import 'package:flutter/material.dart';

/// Шторка деталей местоположения: адрес + привязка страны/города.
class LocationDetailSheet extends StatefulWidget {
  const LocationDetailSheet({super.key, required this.location});

  final LocationModel location;

  static Future<bool?> show(BuildContext context, {required LocationModel location}) {
    final height = MediaQuery.sizeOf(context).height * 0.78;
    return AppBottomSheet.show<bool>(
      context: context,

      title: 'Адрес',
      upperCaseTitle: false,
      showCloseButton: true,
      contentHeight: height,
      contentBottomSpacing: 0,
      content: LocationDetailSheet(location: location),
    );
  }

  @override
  State<LocationDetailSheet> createState() => _LocationDetailSheetState();
}

class _LocationDetailSheetState extends State<LocationDetailSheet> {
  final _repository = sl<LocationRepository>();
  final _scrollController = ScrollController();
  final _primaryController = TextEditingController();
  final _cyrillicController = TextEditingController();
  final _primaryFieldKey = GlobalKey();
  final _cyrillicFieldKey = GlobalKey();

  late LocationModel _original;
  String? _countryCode;
  String? _cityCode;
  late bool _isActive;
  bool _saving = false;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    _applyLocation(widget.location);
    _primaryController.addListener(_onDraftChanged);
    _cyrillicController.addListener(_onDraftChanged);
  }

  @override
  void dispose() {
    _primaryController.removeListener(_onDraftChanged);
    _cyrillicController.removeListener(_onDraftChanged);
    _scrollController.dispose();
    _primaryController.dispose();
    _cyrillicController.dispose();
    super.dispose();
  }

  void _applyLocation(LocationModel location) {
    _original = location;
    _primaryController.text = location.addressPrimary;
    _cyrillicController.text = location.addressCyrillic ?? '';
    _countryCode = location.countryCode;
    _cityCode = location.cityCode;
    _isActive = location.isActive;
  }

  void _onDraftChanged() {
    if (mounted) setState(() {});
  }

  void _scrollFieldIntoView(GlobalKey key) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final targetContext = key.currentContext;
      if (targetContext == null || !mounted) return;
      Scrollable.ensureVisible(
        targetContext,
        alignment: 0.25,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    });
  }

  String get _draftPrimary => _primaryController.text.trim();

  String? get _draftCyrillic {
    final value = _cyrillicController.text.trim();
    return value.isEmpty ? null : value;
  }

  bool get _hasChanges {
    final originalCyrillic = _original.addressCyrillic?.trim();

    return _draftPrimary != _original.addressPrimary.trim() ||
        _draftCyrillic != (originalCyrillic == null || originalCyrillic.isEmpty ? null : originalCyrillic) ||
        _countryCode != _original.countryCode ||
        _cityCode != _original.cityCode ||
        _isActive != _original.isActive;
  }

  bool get _canSave => _hasChanges && !_saving && !_deleting && _draftPrimary.isNotEmpty;

  void _onCountryChanged(String code) {
    setState(() {
      _countryCode = code;
      _cityCode = null;
    });
  }

  void _onCityChanged(String code) {
    setState(() => _cityCode = code);
  }

  void _onActiveChanged(bool isActive) {
    setState(() => _isActive = isActive);
  }

  Future<void> _acceptChanges() async {
    FocusScope.of(context).unfocus();

    if (!_canSave) {
      if (!_hasChanges) {
        Navigator.of(context).pop(false);
      }
      return;
    }

    setState(() => _saving = true);

    try {
      final original = _original;
      final countryChanged = _countryCode != original.countryCode;
      final cityChanged = _cityCode != original.cityCode;
      final geoChanged = countryChanged || cityChanged;

      final hadBinding = original.hasGeoBinding;
      final hasBinding =
          _countryCode != null && _countryCode!.isNotEmpty && _cityCode != null && _cityCode!.isNotEmpty;

      final primaryChanged = _draftPrimary != original.addressPrimary.trim();
      final originalCyrillic = original.addressCyrillic?.trim();
      final normalizedOriginalCyrillic = originalCyrillic == null || originalCyrillic.isEmpty
          ? null
          : originalCyrillic;
      final cyrillicChanged = _draftCyrillic != normalizedOriginalCyrillic;

      await _repository.update(
        id: original.id,
        addressPrimary: primaryChanged ? _draftPrimary : null,
        addressCyrillic: cyrillicChanged ? (_draftCyrillic ?? '') : null,
        clearAddressCyrillic: cyrillicChanged && _draftCyrillic == null && normalizedOriginalCyrillic != null,
        clearGeoBinding: geoChanged && !hasBinding && hadBinding,
        countryCode: geoChanged && hasBinding ? _countryCode : null,
        cityCode: geoChanged && hasBinding ? _cityCode : null,
        isActive: _isActive != original.isActive ? _isActive : null,
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Не удалось сохранить изменения')));
    }
  }

  Future<void> _confirmDelete() async {
    if (_deleting || _saving) return;

    FocusScope.of(context).unfocus();

    final confirmed = await AppDialog.showConfirm(
      context: context,
      title: 'Удалить местоположение?',
      message: 'Это действие нельзя отменить.',
      confirmLabel: 'Удалить',
      confirmIsDestructive: true,
    );

    if (confirmed != true || !mounted) return;

    setState(() => _deleting = true);

    try {
      await _repository.delete(id: _original.id);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _deleting = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Не удалось удалить')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final hasBinding =
        _countryCode != null && _countryCode!.isNotEmpty && _cityCode != null && _cityCode!.isNotEmpty;
    final busy = _saving || _deleting;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.translucent,
      child: SingleChildScrollView(
        controller: _scrollController,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.only(bottom: keyboardInset + 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Listener(
              onPointerDown: (_) => _scrollFieldIntoView(_primaryFieldKey),
              child: KeyedSubtree(
                key: _primaryFieldKey,
                child: AppField(
                  controller: _primaryController,
                  labelText: 'Адрес',
                  hintText: 'Abay ave, 150, Almaty',
                  prefixIcon: AppIcons.locationOn.icon,
                  textInputAction: TextInputAction.next,
                  inputFormatters: const [EnglishAddressInputFormatter()],
                  isEnabled: !busy,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Listener(
              onPointerDown: (_) => _scrollFieldIntoView(_cyrillicFieldKey),
              child: KeyedSubtree(
                key: _cyrillicFieldKey,
                child: AppField(
                  controller: _cyrillicController,
                  labelText: 'Адрес (кириллица)',
                  hintText: 'ул. Абая, 150, Алматы (необязательно)',
                  prefixIcon: AppIcons.translate.icon,
                  textInputAction: TextInputAction.done,
                  isEnabled: !busy,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Привязка',
              style: AppTextStyle.base(14, color: AppColors.subTextColor, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              hasBinding
                  ? 'Страна и город привязаны к этому адресу'
                  : 'Выберите страну и город для этого адреса',
              style: AppTextStyle.base(13, color: AppColors.subTextColor, height: 1.35),
            ),
            const SizedBox(height: 14),
            AbsorbPointer(
              absorbing: busy,
              child: Opacity(
                opacity: busy ? 0.55 : 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CountrySingleSelectField(
                      label: 'Страна',
                      hint: 'Выберите страну',
                      value: _countryCode,
                      onChanged: _onCountryChanged,
                    ),
                    const SizedBox(height: 12),
                    CitySingleSelectField(
                      label: 'Город',
                      hint: 'Выберите город',
                      countryCode: _countryCode,
                      value: _cityCode,
                      onChanged: _onCityChanged,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            AppSwitchRow(
              title: 'Активно',
              subtitle: _isActive ? 'Местоположение видно и доступно' : 'Местоположение скрыто и недоступно',
              value: _isActive,
              onChanged: busy ? null : _onActiveChanged,
              enabled: !busy,
            ),
            const SizedBox(height: 24),
            AppButton(
              text: _saving ? 'Сохранение…' : 'Принять изменения',
              isExpanded: true,
              interactive: _canSave,
              onTap: _canSave ? _acceptChanges : null,
            ),
            AppTextButton(
              text: 'Удалить',
              isLoading: _deleting,
              onTap: busy ? null : _confirmDelete,
              child: Text(
                'Удалить',
                style: AppTextStyle.base(
                  16,
                  fontWeight: FontWeight.w700,
                  color: busy ? AppColors.iconMuted : AppColors.error,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
