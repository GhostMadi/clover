import 'package:auto_route/auto_route.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_snack_bar.dart';
import 'package:clover/feature/_attendance_/attendance_analytics/data/attendance_analytics.dart';
import 'package:clover/feature/_attendance_/attendance_analytics/presentation/widget/attendance_analytics_ui.dart';
import 'package:clover/feature/_attendance_/attendance_timesheet/presentation/cubit/attendance_timesheet_cubit.dart';
import 'package:clover/feature/_attendance_/shared/presentation/widget/attendance_screen_shell.dart';
import 'package:clover/feature/_attendance_/shared/presentation/widget/attendance_service_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

@RoutePage()
class AttendanceTimesheetPage extends StatefulWidget {
  const AttendanceTimesheetPage({super.key, required this.workplaceId});

  final String workplaceId;

  @override
  State<AttendanceTimesheetPage> createState() => _AttendanceTimesheetPageState();
}

class _AttendanceTimesheetPageState extends State<AttendanceTimesheetPage> {
  static const _monthNames = [
    'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
    'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь',
  ];

  late final AttendanceTimesheetCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = sl<AttendanceTimesheetCubit>()..load(widget.workplaceId);
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = AttendanceAnalytics.today;

    return BlocBuilder<AttendanceTimesheetCubit, AttendanceTimesheetState>(
      bloc: _cubit,
      builder: (context, state) {
        final overview = state is AttendanceTimesheetLoaded ? state.overview : null;
        final loading = state is AttendanceTimesheetLoading || state is AttendanceTimesheetInitial;

        return AttendanceScreenShell(
          title: 'Табель',
          body: loading
              ? Center(
                  child: CircularProgressIndicator(
                    color: context.colors.serviceAccent(kAttendanceService).icon,
                  ),
                )
              : ListView(
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
                      onTap: () async {
                        try {
                          final ok = await _cubit.exportCsv();
                          if (!context.mounted) return;
                          if (!ok) {
                            AppSnackBar.show(context, message: 'Нет данных для экспорта', kind: AppSnackBarKind.info);
                          }
                        } catch (_) {
                          if (!context.mounted) return;
                          AppSnackBar.show(context, message: 'Не удалось экспортировать', kind: AppSnackBarKind.error);
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'CSV открывается в Excel и Numbers. Список часов — с сервера за период.',
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
                                    style: AppTextStyle.base(
                                      15,
                                      color: context.colors.textColor,
                                      fontWeight: FontWeight.w700,
                                    ),
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
}
