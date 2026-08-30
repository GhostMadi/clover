import 'package:auto_route/auto_route.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/shared/app_functional_button/app_functional_screen.dart';
import 'package:clover/core/shared/app_functional_button/functional_button_item.dart';
import 'package:clover/core/shared/app_functional_button/map_functional_buttons.dart';
import 'package:clover/core/shared/app_map/app_map.dart';
import 'package:clover/core/shared/app_snack_bar.dart';
import 'package:clover/feature/_catalog_/location/data/repository/location_repository.dart';
import 'package:clover/feature/_catalog_/location/presentation/widget/location_create_map_view.dart';
import 'package:flutter/material.dart';

@RoutePage()
class LocationCreatePage extends StatefulWidget {
  const LocationCreatePage({super.key});

  @override
  State<LocationCreatePage> createState() => _LocationCreatePageState();
}

class _LocationCreatePageState extends State<LocationCreatePage> {
  static const _defaultCenter = AppMapPoint(latitude: 43.238949, longitude: 76.889709);

  final _repository = sl<LocationRepository>();
  final _cyrillicController = TextEditingController();
  final _secondaryController = TextEditingController();
  final _mapController = AppMapController();

  AppMapPoint? _selectedPoint;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _cyrillicController.addListener(_onFormChanged);
    _secondaryController.addListener(_onFormChanged);
  }

  @override
  void dispose() {
    _cyrillicController.removeListener(_onFormChanged);
    _secondaryController.removeListener(_onFormChanged);
    _cyrillicController.dispose();
    _secondaryController.dispose();
    super.dispose();
  }

  void _onFormChanged() => setState(() {});

  bool get _canProceed {
    final address = _cyrillicController.text.trim();
    return !_submitting && _selectedPoint != null && address.isNotEmpty;
  }

  Future<void> _submit() async {
    if (!_canProceed) return;

    final cyrillic = _cyrillicController.text.trim();
    final secondary = _secondaryController.text.trim();

    setState(() => _submitting = true);

    try {
      await _repository.create(
        addressPrimary: cyrillic,
        addressCyrillic: secondary.isEmpty ? null : secondary,
        latitude: _selectedPoint!.latitude,
        longitude: _selectedPoint!.longitude,
      );

      if (!mounted) return;
      AppSnackBar.show(context, message: 'Местоположение добавлено', kind: AppSnackBarKind.success);
      context.router.maybePop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      AppSnackBar.show(context, message: 'Не удалось сохранить', kind: AppSnackBarKind.error);
    }
  }

  Future<void> _moveToMyLocation() async {
    await _mapController.moveToMyLocation();
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return AppFunctionalScreen(
      backgroundColor: Colors.transparent,
      body: LocationCreateMapView(
        mapController: _mapController,
        cyrillicController: _cyrillicController,
        secondaryController: _secondaryController,
        initialCenter: _defaultCenter,
        selectedPoint: _selectedPoint,
        onPointSelected: (point) => setState(() => _selectedPoint = point),
      ),
      buttons: [
        FunctionalButtonItem(
          icon: AppIcons.back.icon,
          keepWhenCollapsed: true,
          customColor: context.colors.primary,
          isLoading: _submitting,
          onTap: () => context.router.maybePop(),
        ),
        ...MapFunctionalButtons.controls(
          onZoomIn: _submitting ? () {} : _mapController.zoomIn,
          onZoomOut: _submitting ? () {} : _mapController.zoomOut,
          onMyLocation: _submitting ? () {} : _moveToMyLocation,
        ),
        if (_canProceed || _submitting)
          FunctionalButtonItem(
            icon: AppIcons.arrowForward.icon,
            label: 'Далее',
            customColor: context.colors.primary,
            iconColor: context.colors.textInverse,
            textColor: context.colors.textInverse,
            isLoading: _submitting,
            onTap: _submit,
          ),
      ],
    );
  }
}
