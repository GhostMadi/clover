import 'package:auto_route/auto_route.dart';
import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/router/app_router.gr.dart';
import 'package:clover/feature/_attendance_/shared/data/attendance_payroll_calc.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_payroll_models.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_snapshot.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_workplace.dart';
import 'package:clover/feature/_attendance_/shared/presentation/widget/attendance_hub_nav_card.dart';
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
    return AttendanceHubNavGrid(
      children: [
        AttendanceHubNavCard(
          title: 'Геозона',
          subtitle: _geofenceSubtitle(workplace),
          icon: AppIcons.locationOn.icon,
          onTap: () => context.router.push(AttendanceGeofenceRoute(workplaceId: workplaceId)),
        ),
        AttendanceHubNavCard(
          title: 'Отметки',
          subtitle: _punchTypesSubtitle(workplace),
          icon: AppIcons.schedule.icon,
          onTap: () => context.router.push(AttendancePunchTypesRoute(workplaceId: workplaceId)),
        ),
        AttendanceHubNavCard(
          title: 'Зарплата',
          subtitle: _payrollSubtitle(workplace, snapshot),
          icon: AppIcons.payments.icon,
          onTap: () => context.router.push(AttendancePayrollRulesRoute(workplaceId: workplaceId)),
        ),
      ],
    );
  }

  static String _geofenceSubtitle(AttendanceWorkplace workplace) {
    if (!workplace.hasGeofenceCenter) return 'Точка не задана';
    return 'Радиус ${workplace.geofenceRadiusM} м';
  }

  static String _payrollSubtitle(AttendanceWorkplace workplace, AttendanceSnapshot? snap) {
    if (snap == null) return 'Правила начисления';
    final summary = AttendancePayrollCalc.teamSummary(workplace, snapshot: snap);
    return '${summary.periodLabel} · ${attendanceFormatMoney(summary.netPay)}';
  }

  static String _punchTypesSubtitle(AttendanceWorkplace workplace) {
    final parts = <String>[];
    if (workplace.clockInEnabled) {
      parts.add(
        workplace.clockInScheduledTime != null
            ? 'Пришёл ${workplace.clockInScheduledTime!.labelRu}'
            : 'Пришёл',
      );
    }
    if (workplace.clockOutEnabled) {
      parts.add(
        workplace.clockOutScheduledTime != null
            ? 'Ушёл ${workplace.clockOutScheduledTime!.labelRu}'
            : 'Ушёл',
      );
    }
    if (workplace.customPunches.isNotEmpty) {
      parts.add('${workplace.customPunches.length} свои');
    }
    return parts.isEmpty ? 'Не настроено' : parts.join(' · ');
  }
}
