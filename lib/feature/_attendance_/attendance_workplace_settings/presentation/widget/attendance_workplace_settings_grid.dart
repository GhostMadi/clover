import 'package:auto_route/auto_route.dart';
import 'package:clover/core/extension/context.dart';
import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/router/app_router.gr.dart';
import 'package:clover/feature/_attendance_/shared/data/attendance_payroll_calc.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_payroll_models.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_snapshot.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_workplace.dart';
import 'package:clover/feature/_attendance_/shared/presentation/widget/attendance_hub_nav_card.dart';
import 'package:clover/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Сетка пунктов настроек компании.
class AttendanceWorkplaceSettingsGrid extends StatelessWidget {
  const AttendanceWorkplaceSettingsGrid({
    super.key,
    required this.workplaceId,
    required this.workplace,
    this.snapshot,
  });

  final String workplaceId;
  final AttendanceWorkplace workplace;
  final AttendanceSnapshot? snapshot;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AttendanceHubNavGrid(
      children: [
        AttendanceHubNavCard(
          title: l10n.attendance_geofence_title,
          subtitle: _geofenceSubtitle(l10n, workplace),
          icon: AppIcons.locationOn.icon,
          onTap: () => context.router.push(AttendanceGeofenceRoute(workplaceId: workplaceId)),
        ),
        AttendanceHubNavCard(
          title: l10n.attendance_analytics_punches,
          subtitle: _punchTypesSubtitle(l10n, workplace),
          icon: AppIcons.schedule.icon,
          onTap: () => context.router.push(AttendancePunchTypesRoute(workplaceId: workplaceId)),
        ),
        AttendanceHubNavCard(
          title: l10n.attendance_payroll_title,
          subtitle: _payrollSubtitle(l10n, workplace, snapshot),
          icon: AppIcons.payments.icon,
          onTap: () => context.router.push(AttendancePayrollRulesRoute(workplaceId: workplaceId)),
        ),
      ],
    );
  }

  static String _geofenceSubtitle(AppLocalizations l10n, AttendanceWorkplace workplace) {
    if (!workplace.hasGeofenceCenter) return l10n.attendance_geofence_point_unset;
    return l10n.attendance_radius_label(workplace.geofenceRadiusM);
  }

  static String _payrollSubtitle(
    AppLocalizations l10n,
    AttendanceWorkplace workplace,
    AttendanceSnapshot? snap,
  ) {
    if (snap == null) return l10n.attendance_payroll_rules_hint;
    final summary = AttendancePayrollCalc.teamSummary(workplace, snapshot: snap);
    return '${summary.periodLabel} · ${attendanceFormatMoney(summary.netPay)}';
  }

  static String _punchTypesSubtitle(AppLocalizations l10n, AttendanceWorkplace workplace) {
    final parts = <String>[];
    if (workplace.clockInEnabled) {
      parts.add(
        workplace.clockInScheduledTime != null
            ? l10n.attendance_clock_in_at(workplace.clockInScheduledTime!.labelRu)
            : l10n.attendance_punch_clock_in,
      );
    }
    if (workplace.clockOutEnabled) {
      parts.add(
        workplace.clockOutScheduledTime != null
            ? l10n.attendance_clock_out_at(workplace.clockOutScheduledTime!.labelRu)
            : l10n.attendance_punch_clock_out,
      );
    }
    if (workplace.customPunches.isNotEmpty) {
      parts.add(l10n.attendance_custom_count(workplace.customPunches.length));
    }
    return parts.isEmpty ? l10n.attendance_settings_not_configured : parts.join(' · ');
  }
}
