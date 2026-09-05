import 'package:auto_route/auto_route.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_snack_bar.dart';
import 'package:clover/feature/_attendance_/attendance_analytics/data/attendance_analytics.dart';
import 'package:clover/feature/_attendance_/attendance_analytics/presentation/widget/attendance_analytics_ui.dart';
import 'package:clover/feature/_attendance_/shared/data/attendance_context_store.dart';
import 'package:clover/feature/_attendance_/shared/data/attendance_timesheet_export.dart';
import 'package:clover/feature/_attendance_/shared/presentation/widget/attendance_screen_shell.dart';
import 'package:clover/feature/_attendance_/shared/presentation/widget/attendance_service_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

@RoutePage()
class AttendanceTimesheetPage extends StatelessWidget {
  const AttendanceTimesheetPage({super.key, required this.workplaceId});

  final String workplaceId;

  static const _monthNames = [
    'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
    'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь',
  ];

  @override
  Widget build(BuildContext context) {
    final store = sl<AttendanceContextStore>();

    return ValueListenableBuilder(
      valueListenable: store.snapshot,
      builder: (context, snap, _) {
        final now = AttendanceAnalytics.today;
        final start = DateTime(now.year, now.month, 1);
        final end = now;
        final overview = snap == null
            ? null
            : AttendanceAnalytics.overview(
                snapshot: snap,
                workplaceId: workplaceId,
                start: start,
                end: end,
              );

        return AttendanceScreenShell(
          title: 'Табель',
          body: ListView(
            padding: EdgeInsets.fromLTRB(16, 8, 16, AttendanceScreenShell.scrollBottomGap(context)),
            children: [
              Text(
                '${_monthNames[now.month - 1]} ${now.year}',
                style: AppTextStyle.base(14, color: context.colors.subTextColor),
              ),
              const SizedBox(height: 12),
              AttendancePrimaryButton(
                text: 'Экспорт CSV (Excel)',
                isExpanded: true,
                onTap: () => _export(context, store, start, end),
              ),
              const SizedBox(height: 8),
              Text(
                'CSV открывается в Excel и Numbers.',
                style: AppTextStyle.base(12, color: context.colors.subTextColor),
              ),
              const SizedBox(height: 16),
              if (overview == null || overview.workers.isEmpty)
                Text('Нет данных за период', style: AppTextStyle.base(15, color: context.colors.subTextColor))
              else
                for (var i = 0; i < overview.workers.length; i++)
                  Padding(
                    padding: EdgeInsets.only(bottom: i == overview.workers.length - 1 ? 0 : 8),
                    child: AttendanceAnalyticsCard(
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              overview.workers[i].displayName,
                              style: AppTextStyle.base(15, color: context.colors.textColor, fontWeight: FontWeight.w700),
                            ),
                          ),
                          Text(
                            overview.workers[i].totalHoursLabel,
                            style: AppTextStyle.base(15, color: context.colors.subTextColor),
                          ),
                        ],
                      ),
                    ),
                  ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _export(
    BuildContext context,
    AttendanceContextStore store,
    DateTime start,
    DateTime end,
  ) async {
    final snap = store.snapshot.value;
    if (snap == null) return;
    try {
      final file = await AttendanceTimesheetExport.exportCsv(
        snapshot: snap,
        workplaceId: workplaceId,
        start: start,
        end: end,
      );
      await Clipboard.setData(ClipboardData(text: file.path));
      if (!context.mounted) return;
      AppSnackBar.show(context, message: 'CSV сохранён · путь в буфере', kind: AppSnackBarKind.success);
    } catch (_) {
      if (!context.mounted) return;
      AppSnackBar.show(context, message: 'Не удалось экспортировать', kind: AppSnackBarKind.error);
    }
  }
}
