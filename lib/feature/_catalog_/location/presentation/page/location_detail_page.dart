import 'package:auto_route/auto_route.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_button.dart';
import 'package:clover/core/shared/app_dialog.dart';
import 'package:clover/core/shared/app_field.dart';
import 'package:clover/core/shared/app_field/english_address_input_formatter.dart';
import 'package:clover/core/shared/app_snack_bar.dart';
import 'package:clover/core/shared/app_switch.dart';
import 'package:clover/core/shared/app_text_button.dart';
import 'package:clover/feature/_catalog_/city/presentation/widget/city_single_select_field.dart';
import 'package:clover/feature/_catalog_/countries/presentation/widget/country_single_select_field.dart';
import 'package:clover/feature/_catalog_/location/data/models/location_model.dart';
import 'package:clover/feature/_catalog_/location/data/repository/location_repository.dart';
import 'package:clover/feature/_settings_/settings/presentation/widget/settings_screen_shell.dart';
import 'package:flutter/material.dart';
import 'package:clover/core/extension/context.dart';

/// Детальная страница местоположения (адрес, привязка, активность).
@RoutePage()
class LocationDetailPage extends StatefulWidget {
  const LocationDetailPage({
    super.key,
    required this.locationId,
    this.initialTitle,
  });

  final String locationId;
  final String? initialTitle;

  @override
  State<LocationDetailPage> createState() => _LocationDetailPageState();
}

class _LocationDetailPageState extends State<LocationDetailPage> {
  final _repository = sl<LocationRepository>();
  final _scrollController = ScrollController();
  final _primaryController = TextEditingController();
  final _cyrillicController = TextEditingController();
  final _primaryFieldKey = GlobalKey();
  final _cyrillicFieldKey = GlobalKey();

  LocationModel? _original;
  String? _countryCode;
  String? _cityCode;
  bool _isActive = true;
  bool _loading = true;
  bool _missing = false;
  bool _saving = false;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    _primaryController.addListener(_onDraftChanged);
    _cyrillicController.addListener(_onDraftChanged);
    _load();
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

  Future<void> _load() async {
    try {
      final row = await _repository.getById(widget.locationId);
      if (!mounted) return;
      if (row == null) {
        setState(() {
          _loading = false;
          _missing = true;
        });
        return;
      }
      _applyLocation(row);
      setState(() {
        _loading = false;
        _missing = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _missing = true;
      });
    }
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
    final original = _original;
    if (original == null) return false;
    final originalCyrillic = original.addressCyrillic?.trim();

    return _draftPrimary != original.addressPrimary.trim() ||
        _draftCyrillic != (originalCyrillic == null || originalCyrillic.isEmpty ? null : originalCyrillic) ||
        _countryCode != original.countryCode ||
        _cityCode != original.cityCode ||
        _isActive != original.isActive;
  }

  bool get _canSave => _hasChanges && !_saving && !_deleting && _draftPrimary.isNotEmpty;

  Future<void> _acceptChanges() async {
    final original = _original;
    if (original == null || !_canSave) return;

    FocusScope.of(context).unfocus();
    setState(() => _saving = true);

    try {
      final countryChanged = _countryCode != original.countryCode;
      final cityChanged = _cityCode != original.cityCode;
      final geoChanged = countryChanged || cityChanged;

      final hadBinding = original.hasGeoBinding;
      final hasBinding =
          _countryCode != null && _countryCode!.isNotEmpty && _cityCode != null && _cityCode!.isNotEmpty;

      final primaryChanged = _draftPrimary != original.addressPrimary.trim();
      final originalCyrillic = original.addressCyrillic?.trim();
      final normalizedOriginalCyrillic =
          originalCyrillic == null || originalCyrillic.isEmpty ? null : originalCyrillic;
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
      context.router.pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      AppSnackBar.show(
        context,
        message: context.l10n.catalog_location_save_failed,
        kind: AppSnackBarKind.error,
      );
    }
  }

  Future<void> _confirmDelete() async {
    if (_deleting || _saving || _original == null) return;

    FocusScope.of(context).unfocus();

    final confirmed = await AppDialog.showConfirm(
      context: context,
      title: context.l10n.catalog_location_delete_title,
      message: context.l10n.common_delete_confirm_irreversible,
      confirmLabel: context.l10n.common_delete,
      confirmIsDestructive: true,
    );

    if (confirmed != true || !mounted) return;

    setState(() => _deleting = true);

    try {
      await _repository.delete(id: _original!.id);
      if (!mounted) return;
      context.router.pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _deleting = false);
      AppSnackBar.show(
        context,
        message: context.l10n.common_could_not_delete,
        kind: AppSnackBarKind.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = context.colors.serviceAccent(kResourcesService);
    final title = _original?.displayTitle ?? widget.initialTitle?.trim();
    final pageTitle = (title != null && title.isNotEmpty) ? title : context.l10n.catalog_location;

    if (_loading) {
      return SettingsScreenShell(
        title: pageTitle,
        service: kResourcesService,
        body: Center(child: CircularProgressIndicator(color: accent.icon)),
      );
    }

    if (_missing || _original == null) {
      return SettingsScreenShell(
        title: context.l10n.catalog_location,
        service: kResourcesService,
        body: Center(
          child: Text(
            context.l10n.catalog_location_not_found,
            style: AppTextStyle.base(15, color: context.colors.subTextColor),
          ),
        ),
      );
    }

    final busy = _saving || _deleting;
    final hasBinding =
        _countryCode != null && _countryCode!.isNotEmpty && _cityCode != null && _cityCode!.isNotEmpty;

    return SettingsScreenShell(
      title: pageTitle,
      service: kResourcesService,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: ListView(
          controller: _scrollController,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(16, 0, 16, SettingsScreenShell.scrollBottomGap(context)),
          children: [
            Listener(
              onPointerDown: (_) => _scrollFieldIntoView(_primaryFieldKey),
              child: KeyedSubtree(
                key: _primaryFieldKey,
                child: AppField(
                  controller: _primaryController,
                  labelText: context.l10n.common_address,
                  hintText: 'Abay ave, 150, Almaty',
                  prefixIcon: AppIcons.locationOn.icon,
                  textInputAction: TextInputAction.next,
                  inputFormatters: const [EnglishAddressInputFormatter()],
                  isEnabled: !busy,
                  service: kResourcesService,
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
                  labelText: context.l10n.catalog_address_cyrillic,
                  hintText: context.l10n.catalog_address_hint,
                  prefixIcon: AppIcons.translate.icon,
                  textInputAction: TextInputAction.done,
                  isEnabled: !busy,
                  service: kResourcesService,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              context.l10n.catalog_binding,
              style: AppTextStyle.base(14, color: context.colors.subTextColor, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              hasBinding
                  ? context.l10n.catalog_bound_yes
                  : context.l10n.catalog_bound_no,
              style: AppTextStyle.base(13, color: context.colors.subTextColor, height: 1.35),
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
                      label: context.l10n.catalog_country_sheet_title,
                      hint: context.l10n.common_pick_country,
                      value: _countryCode,
                      service: kResourcesService,
                      onChanged: (code) => setState(() {
                        _countryCode = code;
                        _cityCode = null;
                      }),
                    ),
                    const SizedBox(height: 12),
                    CitySingleSelectField(
                      label: context.l10n.catalog_city_sheet_title,
                      hint: context.l10n.common_pick_city,
                      countryCode: _countryCode,
                      value: _cityCode,
                      service: kResourcesService,
                      onChanged: (code) => setState(() => _cityCode = code),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            AppSwitchRow(
              title: context.l10n.common_active,
              subtitle: _isActive ? context.l10n.catalog_location_active_on : context.l10n.catalog_location_active_off,
              value: _isActive,
              onChanged: busy ? null : (v) => setState(() => _isActive = v),
              enabled: !busy,
              service: kResourcesService,
            ),
            const SizedBox(height: 24),
            AppButton(
              text: _saving ? context.l10n.common_saving : context.l10n.catalog_accept_changes,
              isExpanded: true,
              interactive: _canSave,
              service: kResourcesService,
              onTap: _canSave ? _acceptChanges : null,
            ),
            AppTextButton(
              text: context.l10n.common_delete,
              isLoading: _deleting,
              onTap: busy ? null : _confirmDelete,
              child: Text(
                context.l10n.common_delete,
                style: AppTextStyle.base(
                  16,
                  fontWeight: FontWeight.w700,
                  color: busy ? context.colors.iconMuted : context.colors.error,
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
