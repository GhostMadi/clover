import 'package:auto_route/auto_route.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/router/app_router.gr.dart';
import 'package:clover/core/shared/app_tile.dart';
import 'package:clover/feature/_attendance_/shared/data/attendance_context_store.dart';
import 'package:clover/feature/_attendance_/shared/data/attendance_payroll_mock.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_payroll_models.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_workplace.dart';
import 'package:clover/feature/_attendance_/shared/presentation/widget/attendance_screen_shell.dart';
import 'package:clover/feature/_attendance_/shared/presentation/widget/attendance_service_ui.dart';
import 'package:flutter/material.dart';

@RoutePage()
class AttendanceWorkplaceSettingsPage extends StatelessWidget {
  const AttendanceWorkplaceSettingsPage({super.key, required this.workplaceId});

  final String workplaceId;

  @override
  Widget build(BuildContext context) {
    final store = sl<AttendanceContextStore>();

    return ValueListenableBuilder(
      valueListenable: store.snapshot,
      builder: (context, snap, _) {
        final workplace = snap?.workplaceById(workplaceId);
        if (workplace == null) {
          return AttendanceScreenShell(
            title: 'Настройки',
            body: Center(
              child: Text('Компания не найдена', style: AppTextStyle.base(15, color: context.colors.subTextColor)),
            ),
          );
        }

        return AttendanceScreenShell(
          title: 'Настройки',
          body: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(16, 8, 16, AttendanceScreenShell.scrollBottomGap(context)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  workplace.name,
                  style: AppTextStyle.base(18, color: context.colors.textColor, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'Геозона, отметки и правила начисления зарплаты.',
                  style: AppTextStyle.base(14, color: context.colors.subTextColor),
                ),
                const SizedBox(height: 16),
                AppTileGroup(
                  children: [
                    AttendanceServiceTile(
                      title: 'Геозона',
                      subtitle: _geofenceSubtitle(workplace),
                      icon: AppIcons.locationOn.icon,
                      showChevron: true,
                      onTap: () => context.router.push(AttendanceGeofenceRoute(workplaceId: workplaceId)),
                    ),
                    AttendanceServiceTile(
                      title: 'Типы отметок',
                      subtitle: _punchTypesSubtitle(workplace),
                      icon: AppIcons.schedule.icon,
                      showChevron: true,
                      onTap: () => context.router.push(AttendancePunchTypesRoute(workplaceId: workplaceId)),
                    ),
                    AttendanceServiceTile(
                      title: 'Зарплата',
                      subtitle: _payrollSubtitle(workplace),
                      icon: AppIcons.payments.icon,
                      showChevron: true,
                      onTap: () => context.router.push(AttendancePayrollRulesRoute(workplaceId: workplaceId)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _geofenceSubtitle(AttendanceWorkplace workplace) {
    if (!workplace.hasGeofenceCenter) return 'Точка не задана';
    return 'Радиус ${workplace.geofenceRadiusM} м';
  }

  String _payrollSubtitle(AttendanceWorkplace workplace) {
    final store = sl<AttendanceContextStore>();
    final summary = AttendancePayrollMock.teamSummary(workplace, snapshot: store.snapshot.value);
    return '${summary.periodLabel} · ${attendanceFormatMoney(summary.netPay)} к выплате';
  }

  String _punchTypesSubtitle(AttendanceWorkplace workplace) {
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
