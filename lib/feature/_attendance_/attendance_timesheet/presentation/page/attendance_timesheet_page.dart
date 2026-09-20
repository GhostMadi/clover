import 'package:auto_route/auto_route.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_snack_bar.dart';
import 'package:clover/feature/_attendance_/attendance_analytics/data/attendance_analytics.dart';
import 'package:clover/feature/_attendance_/attendance_timesheet/presentation/cubit/attendance_timesheet_cubit.dart';
import 'package:clover/feature/_attendance_/attendance_timesheet/presentation/widget/attendance_timesheet_worker_tile.dart';
import 'package:clover/feature/_attendance_/shared/presentation/widget/attendance_screen_shell.dart';
import 'package:clover/feature/_attendance_/shared/presentation/widget/attendance_section_title.dart';
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

  Future<void> _export() async {
    try {
      final ok = await _cubit.exportCsv();
      if (!mounted) return;
      if (!ok) {
        AppSnackBar.show(context, message: 'Нет данных для экспорта', kind: AppSnackBarKind.info);
      }
    } catch (_) {
      if (!mounted) return;
      AppSnackBar.show(context, message: 'Не удалось экспортировать', kind: AppSnackBarKind.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = AttendanceAnalytics.today;
    final colors = context.colors;

    return BlocBuilder<AttendanceTimesheetCubit, AttendanceTimesheetState>(
      bloc: _cubit,
      builder: (context, state) {
        final overview = state is AttendanceTimesheetLoaded ? state.overview : null;
        final loading = state is AttendanceTimesheetLoading || state is AttendanceTimesheetInitial;
        final workers = overview?.workers ?? const [];

        return AttendanceScreenShell(
          title: 'Табель',
          body: loading
              ? const AttendanceLoader()
              : ListView(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, AttendanceScreenShell.scrollBottomGap(context)),
                  children: [
                    Text(
                      '${_monthNames[now.month - 1]} ${now.year}',
                      style: AppTextStyle.base(14, color: colors.subTextColor, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    AttendancePrimaryButton(
                      text: 'Экспорт CSV',
                      isExpanded: true,
                      height: 48,
                      onTap: _export,
                    ),
                    const SizedBox(height: 20),
                    const AttendanceSectionTitle('Часы'),
                    const SizedBox(height: 8),
                    if (workers.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          'Нет данных за период',
                          style: AppTextStyle.base(14, color: colors.subTextColor),
                        ),
                      )
                    else
                      for (final worker in workers) ...[
                        AttendanceTimesheetWorkerTile(
                          name: worker.displayName,
                          hoursLabel: worker.totalHoursLabel,
                        ),
                        const SizedBox(height: 8),
                      ],
                  ],
                ),
        );
      },
    );
  }
}
