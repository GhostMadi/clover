import 'dart:async';
import 'dart:ui';

import 'package:auto_route/auto_route.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/extension/context.dart';
import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/router/app_router.gr.dart';
import 'package:clover/feature/_attendance_/shared/presentation/widget/attendance_service_ui.dart';
import 'package:clover/core/shared/app_functional_button/app_functional_screen.dart';
import 'package:clover/core/shared/app_map/app_map.dart';
import 'package:clover/core/shared/app_outlined_button.dart';
import 'package:clover/core/shared/app_snack_bar.dart';
import 'package:clover/feature/_attendance_/shared/data/attendance_context_store.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_pending_punch.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_punch_type.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_workplace.dart';
import 'package:flutter/material.dart';

/// Полноэкранное напоминание «Надо отметиться» (карта + CTA).
@RoutePage()
class AttendancePendingPage extends StatefulWidget {
  const AttendancePendingPage({super.key, required this.workplaceId});

  final String workplaceId;

  @override
  State<AttendancePendingPage> createState() => _AttendancePendingPageState();
}

class _AttendancePendingPageState extends State<AttendancePendingPage> {
  static const _defaultCenter = AppMapPoint(latitude: 43.238949, longitude: 76.889709);

  final _mapController = AppMapController();
  bool _mapReady = false;
  bool _cameraFitted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _mapReady = true);
    });
  }

  double _zoomForRadius(int radiusM) {
    if (radiusM <= 75) return 16.5;
    if (radiusM <= 150) return 15.5;
    return 14.5;
  }

  AppMapPoint _centerFor(AttendanceWorkplace? workplace) {
    if (workplace != null && workplace.hasGeofenceCenter) {
      return AppMapPoint(latitude: workplace.latitude!, longitude: workplace.longitude!);
    }
    return _defaultCenter;
  }

  Future<void> _fitCamera(AppMapPoint center, int radiusM) async {
    await _mapController.moveTo(center, zoom: _zoomForRadius(radiusM));
  }

  void _quickPunch(AttendancePendingPunch pending, {required bool inZone}) {
    if (!inZone) {
      AppSnackBar.show(context, message: 'Вы вне зоны — откройте экран отметки', kind: AppSnackBarKind.info);
      context.router.replace(AttendancePunchRoute(workplaceId: pending.workplaceId));
      return;
    }

    final type = pending.kind == AttendancePendingKind.clockIn
        ? AttendancePunchType.clockIn
        : AttendancePunchType.clockOut;
    sl<AttendanceContextStore>().punch(workplaceId: pending.workplaceId, type: type);
    AppSnackBar.show(context, message: '${type.labelRu} — сохранено', kind: AppSnackBarKind.success);
    context.router.maybePop();
  }

  void _snooze() {
    sl<AttendanceContextStore>().snoozePending();
    context.router.maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final store = sl<AttendanceContextStore>();
    final floatingInsets = AppFunctionalScreen.floatingInsets(context);

    return ValueListenableBuilder(
      valueListenable: store.snapshot,
      builder: (context, snap, _) {
        final pending = snap?.resolvePendingPunch();
        if (snap == null || pending == null || pending.workplaceId != widget.workplaceId) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.router.maybePop();
          });
          return Scaffold(backgroundColor: colors.pageBackground);
        }

        final workplace = snap.workplaceById(widget.workplaceId);
        final center = _centerFor(workplace);
        final radiusM = workplace?.geofenceRadiusM ?? 150;
        final inZone = snap.mockInGeofence;

        if (_mapReady && !_cameraFitted && workplace != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _cameraFitted = true;
            unawaited(_fitCamera(center, radiusM));
          });
        }

        return Scaffold(
          backgroundColor: colors.pageBackground,
          extendBody: true,
          body: Stack(
            fit: StackFit.expand,
            children: [
              if (_mapReady && workplace != null)
                Positioned.fill(
                  child: AppMap(
                    controller: _mapController,
                    initialCenter: center,
                    selectedPoint: center,
                    geofenceRadiusM: radiusM.toDouble(),
                  ),
                )
              else
                ColoredBox(color: colors.surfaceMuted),
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                child: Material(
                  color: colors.pageBackground.withValues(alpha: 0.92),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            pending.workplaceName,
                            style: AppTextStyle.base(20, color: colors.textColor, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            pending.prompt,
                            style: AppTextStyle.base(15, color: colors.subTextColor),
                          ),
                          const SizedBox(height: 10),
                          _ZoneBadge(inZone: inZone, radiusM: radiusM),
                          if (workplace != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              '${center.latitude.toStringAsFixed(5)}, ${center.longitude.toStringAsFixed(5)}',
                              style: AppTextStyle.base(12, color: colors.subTextColor),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: floatingInsets.right,
                top: MediaQuery.paddingOf(context).top + kToolbarHeight + 8,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _MapControlButton(icon: AppIcons.addRounded.icon, onTap: _mapController.zoomIn),
                    const SizedBox(height: 8),
                    _MapControlButton(icon: AppIcons.removeRounded.icon, onTap: _mapController.zoomOut),
                    const SizedBox(height: 8),
                    _MapControlButton(icon: AppIcons.myLocation.icon, onTap: _mapController.moveToMyLocation),
                  ],
                ),
              ),
              Positioned(
                left: floatingInsets.left,
                right: floatingInsets.right,
                bottom: floatingInsets.bottom,
                child: _FloatingActionsPanel(
                  children: [
                    AttendancePrimaryButton(
                      text: pending.actionLabel,
                      isExpanded: true,
                      onTap: () => _quickPunch(pending, inZone: inZone),
                    ),
                    const SizedBox(height: 10),
                    AppOutlinedButton(
                      text: 'Подробнее',
                      isExpanded: true,
                      onTap: () => context.router.push(AttendancePunchRoute(workplaceId: pending.workplaceId)),
                    ),
                    const SizedBox(height: 10),
                    AppOutlinedButton(
                      text: 'Позже',
                      isExpanded: true,
                      onTap: _snooze,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Левитирующая панель CTA — те же отступы и стиль, что у [AppFunctionalButtons].
class _FloatingActionsPanel extends StatelessWidget {
  const _FloatingActionsPanel({required this.children});

  final List<Widget> children;

  static const double _figmaRadius = 28;
  static const double _figmaBlurSigma = 24;
  static const double _figmaShadowBlur = 24;
  static const double _figmaShadowOffsetY = 8;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final radius = context.widthByContext(_figmaRadius);
    final blur = context.heightByContext(_figmaBlurSigma).clamp(8.0, 32.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surfaceSoft.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: colors.border.withValues(alpha: 0.7)),
            boxShadow: [
              BoxShadow(
                color: colors.shadowDark.withValues(alpha: 0.10),
                blurRadius: context.heightByContext(_figmaShadowBlur),
                offset: Offset(0, context.heightByContext(_figmaShadowOffsetY)),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: children,
            ),
          ),
        ),
      ),
    );
  }
}

class _ZoneBadge extends StatelessWidget {
  const _ZoneBadge({required this.inZone, required this.radiusM});

  final bool inZone;
  final int radiusM;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bg = inZone ? colors.functionalSoftBlue : colors.functionalSoftRed.withValues(alpha: 0.35);
    final fg = inZone ? colors.functionalSoftBlueIcon : colors.destructive;

    return Align(
      alignment: Alignment.centerLeft,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: inZone ? colors.borderCardBlue.withValues(alpha: 0.85) : colors.destructive.withValues(alpha: 0.35),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Text(
            inZone ? 'Вы в зоне · $radiusM м' : 'Вы вне зоны · $radiusM м',
            style: AppTextStyle.base(13, color: fg, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}

class _MapControlButton extends StatelessWidget {
  const _MapControlButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.surface.withValues(alpha: 0.94),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.borderSoft),
          ),
          child: Icon(icon, size: 20, color: colors.textColor),
        ),
      ),
    );
  }
}
