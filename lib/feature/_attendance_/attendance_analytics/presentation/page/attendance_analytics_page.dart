import 'package:auto_route/auto_route.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/router/app_router.gr.dart';
import 'package:clover/feature/_attendance_/attendance_analytics/data/attendance_analytics.dart';
import 'package:clover/feature/_attendance_/attendance_analytics/presentation/cubit/attendance_analytics_cubit.dart';
import 'package:clover/feature/_attendance_/attendance_analytics/presentation/widget/attendance_analytics_period_picker.dart';
import 'package:clover/feature/_attendance_/attendance_analytics/presentation/widget/attendance_analytics_summary_section.dart';
import 'package:clover/feature/_attendance_/attendance_analytics/presentation/widget/attendance_analytics_team_section.dart';
import 'package:clover/feature/_attendance_/attendance_analytics/presentation/widget/attendance_today_team_section.dart';
import 'package:clover/feature/_attendance_/shared/presentation/widget/attendance_screen_shell.dart';
import 'package:clover/feature/_attendance_/shared/presentation/widget/attendance_service_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

@RoutePage()
class AttendanceAnalyticsPage extends StatefulWidget {
  const AttendanceAnalyticsPage({super.key, required this.workplaceId});

  final String workplaceId;

  @override
  State<AttendanceAnalyticsPage> createState() => _AttendanceAnalyticsPageState();
}

class _AttendanceAnalyticsPageState extends State<AttendanceAnalyticsPage> {
  static const _monthNames = [
    'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
    'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь',
  ];

  late final AttendanceAnalyticsCubit _cubit;
  late DateTime _start;
  late DateTime _end;
  bool _isMonth = true;

  DateTime get _today => AttendanceAnalytics.today;

  @override
  void initState() {
    super.initState();
    _cubit = sl<AttendanceAnalyticsCubit>();
    _applyMonth(anchor: _today);
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  void _reload() {
    _cubit.load(workplaceId: widget.workplaceId, start: _start, end: _end);
  }

  void _applyWeek({DateTime? anchor}) {
    final end = AttendanceAnalytics.dayKey(anchor ?? _today);
    setState(() {
      _isMonth = false;
      _end = end;
      _start = end.subtract(const Duration(days: 6));
    });
    _reload();
  }

  void _applyMonth({DateTime? anchor}) {
    final ref = anchor ?? _today;
    setState(() {
      _isMonth = true;
      _start = DateTime(ref.year, ref.month, 1);
      _end = _clampMonthEnd(DateTime(ref.year, ref.month + 1, 0));
    });
    _reload();
  }

  DateTime _clampMonthEnd(DateTime monthEnd) {
    final end = AttendanceAnalytics.dayKey(monthEnd);
    return end.isAfter(_today) ? _today : end;
  }

  void _shiftPeriod(int delta) {
    if (_isMonth) {
      _applyMonth(anchor: DateTime(_start.year, _start.month + delta, 1));
    } else {
      final newEnd = _end.add(Duration(days: 7 * delta));
      if (newEnd.isAfter(_today)) {
        _applyWeek(anchor: _today);
      } else {
        setState(() {
          _isMonth = false;
          _start = _start.add(Duration(days: 7 * delta));
          _end = newEnd;
        });
        _reload();
      }
    }
  }

  bool get _canGoNext {
    if (_isMonth) {
      return _start.year < _today.year ||
          (_start.year == _today.year && _start.month < _today.month);
    }
    return _end.isBefore(_today);
  }

  String _periodLabel() {
    if (_isMonth && _start.day == 1 && _start.year == _end.year && _start.month == _end.month) {
      return '${_monthNames[_start.month - 1]} ${_start.year}';
    }
    return '${_fmt(_start)} — ${_fmt(_end)}';
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}';

  bool _isTodayPeriod() {
    if (_isMonth) {
      return _start.year == _today.year && _start.month == _today.month && !_end.isBefore(_today);
    }
    return !_end.isBefore(_today) && !_start.isAfter(_today);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AttendanceAnalyticsCubit, AttendanceAnalyticsState>(
      bloc: _cubit,
      builder: (context, state) {
        if (state is AttendanceAnalyticsMissing || state is AttendanceAnalyticsInitial) {
          return AttendanceScreenShell(
            title: 'Аналитика',
            body: Center(
              child: Text('Нет данных', style: AppTextStyle.base(15, color: context.colors.subTextColor)),
            ),
          );
        }

        final overview = state is AttendanceAnalyticsLoaded ? state.overview : null;
        final loading = state is AttendanceAnalyticsLoading || overview == null;

        return AttendanceScreenShell(
          title: 'Аналитика',
          body: loading
              ? const AttendanceLoader()
              : ListView(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, AttendanceScreenShell.scrollBottomGap(context)),
                  children: [
                    AttendanceAnalyticsPeriodPicker(
                      isMonth: _isMonth,
                      onWeek: () => _applyWeek(anchor: _end.isAfter(_today) ? _today : _end),
                      onMonth: () => _applyMonth(anchor: _start),
                      periodLabel: _periodLabel(),
                      onPrevious: () => _shiftPeriod(-1),
                      onNext: () => _shiftPeriod(1),
                      canGoNext: _canGoNext,
                    ),
                    const SizedBox(height: 16),
                    if (_isTodayPeriod()) ...[
                      AttendanceTodayTeamSection(
                        workers: overview.workers,
                        workplaceId: widget.workplaceId,
                      ),
                      const SizedBox(height: 16),
                    ],
                    AttendanceAnalyticsSummarySection(
                      overview: overview,
                      workerCount: overview.workers.length,
                    ),
                    const SizedBox(height: 20),
                    AttendanceAnalyticsTeamSection(
                      workers: overview.workers,
                      onWorkerTap: (worker) {
                        context.router.push(
                          AttendanceWorkerAnalyticsRoute(
                            workplaceId: widget.workplaceId,
                            workerId: worker.id,
                          ),
                        );
                      },
                    ),
                    if (overview.workers.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 24),
                        child: Text(
                          'Нет данных за период',
                          textAlign: TextAlign.center,
                          style: AppTextStyle.base(14, color: context.colors.subTextColor),
                        ),
                      ),
                  ],
                ),
        );
      },
    );
  }
}
