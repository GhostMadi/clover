import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_functional_button/app_functional_screen.dart';
import 'package:clover/core/shared/app_functional_button/functional_button_item.dart';
import 'package:clover/core/shared/app_functional_button/map_functional_buttons.dart';
import 'package:clover/core/shared/app_map/app_map.dart';
import 'package:clover/core/shared/app_snack_bar.dart';
import 'package:clover/feature/_attendance_/attendance_workplace_settings/presentation/cubit/attendance_workplace_settings_cubit.dart';
import 'package:clover/feature/_attendance_/shared/data/attendance_error.dart';
import 'package:clover/feature/_attendance_/shared/data/attendance_outbox.dart';
import 'package:clover/feature/_attendance_/shared/presentation/widget/attendance_service_ui.dart';
import 'package:flutter/material.dart';

@RoutePage()
class AttendanceGeofencePage extends StatefulWidget {
  const AttendanceGeofencePage({super.key, required this.workplaceId});

  final String workplaceId;

  @override
  State<AttendanceGeofencePage> createState() => _AttendanceGeofencePageState();
}

class _AttendanceGeofencePageState extends State<AttendanceGeofencePage> {
  static const _defaultCenter = AppMapPoint(latitude: 43.238949, longitude: 76.889709);

  late final AttendanceWorkplaceSettingsCubit _cubit;
  final _mapController = AppMapController();

  late AppMapPoint _center;
  late int _radius;

  @override
  void initState() {
    super.initState();
    _cubit = sl<AttendanceWorkplaceSettingsCubit>()..bind(widget.workplaceId);
    final w = _cubit.state is AttendanceWorkplaceSettingsReady
        ? (_cubit.state as AttendanceWorkplaceSettingsReady).workplace
        : null;
    _radius = w?.geofenceRadiusM ?? 150;
    _center = w != null && w.hasGeofenceCenter
        ? AppMapPoint(latitude: w.latitude!, longitude: w.longitude!)
        : _defaultCenter;
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  double _zoomForRadius(int radiusM) {
    if (radiusM <= 75) return 16.5;
    if (radiusM <= 150) return 15.5;
    return 14.5;
  }

  Future<void> _fitCamera() async {
    await _mapController.moveTo(_center, zoom: _zoomForRadius(_radius));
  }

  void _onPointSelected(AppMapPoint point) {
    setState(() => _center = point);
    unawaited(_fitCamera());
  }

  void _onRadiusChanged(double value) {
    setState(() => _radius = value.round());
    unawaited(_fitCamera());
  }

  Future<void> _moveToMyLocation() async {
    final (result, point) = await _mapController.moveToMyLocation();
    if (!mounted) return;

    switch (result) {
      case AppMapMyLocationResult.moved:
        if (point == null) return;
        setState(() => _center = point);
        unawaited(_fitCamera());
      case AppMapMyLocationResult.permissionDenied:
        AppSnackBar.show(
          context,
          message: 'Разрешите доступ к геолокации в настройках',
          kind: AppSnackBarKind.error,
        );
      case AppMapMyLocationResult.unavailable:
        AppSnackBar.show(
          context,
          message: 'Не удалось определить местоположение',
          kind: AppSnackBarKind.error,
        );
    }
  }

  Future<void> _save() async {
    try {
      final result = await _cubit.updateGeofence(
        latitude: _center.latitude,
        longitude: _center.longitude,
        geofenceRadiusM: _radius,
      );
      if (!mounted) return;
      AppSnackBar.show(
        context,
        message: result == AttendancePersistResult.queued
            ? 'Сохранено локально, синхронизируется'
            : 'Геозона сохранена',
        kind: AppSnackBarKind.success,
      );
      context.router.maybePop();
    } catch (e) {
      if (!mounted) return;
      final msg = e is AttendanceException ? e.userMessage : 'Не удалось сохранить';
      AppSnackBar.show(context, message: msg, kind: AppSnackBarKind.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bottomPanelBottom = AppFunctionalScreen.scrollBottomClearance(context) + 12;

    return AppFunctionalScreen(
      backgroundColor: colors.pageBackground,
      collapsed: true,
      collapsedBarWidthPerButton: 130,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: AppMap(
              controller: _mapController,
              initialCenter: _center,
              selectedPoint: _center,
              geofenceRadiusM: _radius.toDouble(),
              onPointSelected: _onPointSelected,
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: Material(
              color: colors.pageBackground.withValues(alpha: 0.92),
              child: SafeArea(
                bottom: false,
                child: SizedBox(
                  height: kToolbarHeight,
                  child: Center(
                    child: Text(
                      'Геозона',
                      style: AppTextStyle.base(17, color: colors.textColor, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: bottomPanelBottom,
            child: _GeofenceControlsPanel(
              center: _center,
              radius: _radius,
              onRadiusChanged: _onRadiusChanged,
            ),
          ),
        ],
      ),
      buttons: [
        FunctionalButtonItem(
          icon: AppIcons.back.icon,
          keepWhenCollapsed: true,
          customColor: attendanceServiceAccent(colors).cta,
          iconColor: attendanceServiceAccent(colors).ctaForeground,
          onTap: () => context.router.maybePop(),
        ),
        ...MapFunctionalButtons.controls(
          onZoomIn: _mapController.zoomIn,
          onZoomOut: _mapController.zoomOut,
          onMyLocation: _moveToMyLocation,
        ),
        FunctionalButtonItem(
          icon: AppIcons.checkRounded.icon,
          label: 'Сохранить',
          keepWhenCollapsed: true,
          customColor: attendanceServiceAccent(colors).cta,
          iconColor: attendanceServiceAccent(colors).ctaForeground,
          textColor: attendanceServiceAccent(colors).ctaForeground,
          onTap: _save,
        ),
      ],
    );
  }
}

class _GeofenceControlsPanel extends StatelessWidget {
  const _GeofenceControlsPanel({
    required this.center,
    required this.radius,
    required this.onRadiusChanged,
  });

  final AppMapPoint center;
  final int radius;
  final ValueChanged<double> onRadiusChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderSoft),
        boxShadow: [
          BoxShadow(
            color: colors.shadowDark.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(AppIcons.locationOn.icon, size: 18, color: colors.functionalSoftBlueIcon),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${center.latitude.toStringAsFixed(5)}, ${center.longitude.toStringAsFixed(5)}',
                    style: AppTextStyle.base(14, color: colors.textColor, fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  '$radius м',
                  style: AppTextStyle.base(13, color: colors.functionalSoftBlueIcon, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Тап по карте — переместить центр. Круг — зона отметки.',
              style: AppTextStyle.base(12, color: colors.subTextColor, height: 1.3),
            ),
            const SizedBox(height: 10),
            Text('Радиус', style: AppTextStyle.base(13, color: colors.subTextColor, fontWeight: FontWeight.w600)),
            Slider(
              value: radius.toDouble(),
              min: 50,
              max: 300,
              divisions: 5,
              label: '$radius м',
              onChanged: onRadiusChanged,
            ),
          ],
        ),
      ),
    );
  }
}
