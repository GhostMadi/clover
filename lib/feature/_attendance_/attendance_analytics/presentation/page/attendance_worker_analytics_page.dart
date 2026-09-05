import 'package:auto_route/auto_route.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/app_service_accent.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/feature/_attendance_/attendance_analytics/data/attendance_analytics.dart';
import 'package:clover/feature/_attendance_/attendance_analytics/data/models/attendance_analytics_models.dart';
import 'package:clover/feature/_attendance_/attendance_analytics/presentation/widget/attendance_analytics_ui.dart';
import 'package:clover/feature/_attendance_/attendance_analytics/presentation/widget/attendance_day_detail_card.dart';
import 'package:clover/feature/_attendance_/attendance_analytics/presentation/widget/attendance_day_presence_banner.dart';
import 'package:clover/feature/_attendance_/attendance_analytics/presentation/widget/attendance_mini_calendar.dart';
import 'package:clover/feature/_attendance_/attendance_analytics/presentation/widget/attendance_worker_day_journal.dart';
import 'package:clover/feature/_attendance_/shared/data/attendance_context_store.dart';
import 'package:clover/feature/_attendance_/shared/data/attendance_payroll_mock.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_absence.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_payroll_models.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_punch_record.dart';
import 'package:clover/feature/_attendance_/shared/presentation/widget/attendance_screen_shell.dart';
import 'package:clover/feature/_attendance_/shared/presentation/widget/attendance_service_ui.dart';
import 'package:flutter/material.dart';

@RoutePage()
class AttendanceWorkerAnalyticsPage extends StatefulWidget {
  const AttendanceWorkerAnalyticsPage({
    super.key,
    required this.workplaceId,
    required this.workerId,
  });

  final String workplaceId;
  final String workerId;

  @override
  State<AttendanceWorkerAnalyticsPage> createState() => _AttendanceWorkerAnalyticsPageState();
}

class _AttendanceWorkerAnalyticsPageState extends State<AttendanceWorkerAnalyticsPage> {
  late DateTime _selectedDay;
  final _store = sl<AttendanceContextStore>();

  @override
  void initState() {
    super.initState();
    _selectedDay = AttendanceAnalytics.today;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: _store.snapshot,
      builder: (context, snap, _) {
        final now = AttendanceAnalytics.today;
        final start = DateTime(now.year, now.month, 1);
        final end = now;

        final worker = snap == null
            ? null
            : AttendanceAnalytics.worker(
                snapshot: snap,
                workplaceId: widget.workplaceId,
                workerId: widget.workerId,
                start: start,
                end: end,
              );

        if (worker == null) {
          return AttendanceScreenShell(
            title: 'Сотрудник',
            body: Center(
              child: Text('Не найден', style: AppTextStyle.base(15, color: context.colors.subTextColor)),
            ),
          );
        }

        final selectedKey = AttendanceAnalytics.dayKey(_selectedDay);
        final dayRecord = worker.daysByKey[selectedKey] ??
            AttendanceWorkerDayRecord(date: selectedKey, status: AttendanceDayStatus.off, totalMinutes: 0);
        final isToday = selectedKey == AttendanceAnalytics.today;

        final workplace = snap?.workplaceById(widget.workplaceId);
        final payroll = workplace == null
            ? null
            : AttendancePayrollMock.forWorkplace(workplace, snapshot: snap)
                .where((e) => e.workerId == widget.workerId)
                .firstOrNull;

        final absences = snap?.absences
                .where((a) => a.workplaceId == widget.workplaceId && a.workerId == widget.workerId)
                .toList() ??
            const [];

        final punches = snap?.punchHistoryFor(
              workplaceId: widget.workplaceId,
              workerId: widget.workerId,
              includeCancelled: true,
            ) ??
            const <AttendancePunchRecord>[];

        final monthLabel = _monthLabel(now);
        final colors = context.colors;
        final accent = attendanceServiceAccent(colors);
        final workerAccent = attendanceWorkerAccent(colors, attendanceWorkerAccentSeed(worker.id));

        return AttendanceScreenShell(
          title: worker.displayName,
          body: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(16, 8, 16, AttendanceScreenShell.scrollBottomGap(context)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _WorkerHeroCard(
                  worker: worker,
                  monthLabel: monthLabel,
                  accent: workerAccent,
                  serviceAccent: accent,
                ),
                const SizedBox(height: 14),
                _MonthMetricsGrid(worker: worker),
                if (payroll != null) ...[
                  const SizedBox(height: 20),
                  _PayrollPreviewCard(payroll: payroll),
                ],
                if (absences.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  AttendanceAnalyticsSectionHeader(
                    title: 'Отсутствия',
                    subtitle: 'Оформленные периоды · не считаются пропуском',
                  ),
                  const SizedBox(height: 12),
                  for (final a in absences)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: AttendanceAnalyticsCard(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            AttendanceMetricIcon(
                              icon: AppIcons.eventBusy.icon,
                              tint: attendanceYellowAccent(colors).icon,
                              bg: attendanceYellowAccent(colors).surface,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    a.kind.labelRu,
                                    style: AppTextStyle.base(15, color: colors.textColor, fontWeight: FontWeight.w700),
                                  ),
                                  Text(
                                    '${_shortDate(a.startDate)} — ${_shortDate(a.endDate)}',
                                    style: AppTextStyle.base(13, color: colors.subTextColor),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
                const SizedBox(height: 20),
                AttendanceAnalyticsSectionHeader(
                  title: 'Календарь',
                  subtitle: monthLabel,
                ),
                const SizedBox(height: 12),
                AttendanceMiniCalendar(
                  selectedDay: _selectedDay,
                  daysByKey: worker.daysByKey,
                  onDaySelected: (day) => setState(() => _selectedDay = day),
                ),
                const SizedBox(height: 16),
                AttendanceDayPresenceBanner(
                  record: dayRecord,
                  highlightToday: isToday,
                ),
                const SizedBox(height: 16),
                AttendanceDayDetailCard(record: dayRecord),
                const SizedBox(height: 20),
                AttendanceWorkerDayJournal(
                  daysByKey: worker.daysByKey,
                  selectedDay: _selectedDay,
                  onDaySelected: (day) => setState(() => _selectedDay = day),
                ),
                if (punches.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  AttendanceAnalyticsSectionHeader(
                    title: 'История отметок',
                    subtitle: 'Последние события с устройства',
                  ),
                  const SizedBox(height: 12),
                  AttendanceAnalyticsCard(
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
                    child: Column(
                      children: [
                        for (var i = 0; i < punches.length && i < 8; i++) ...[
                          _PunchHistoryRow(record: punches[i]),
                          if (i < punches.length - 1 && i < 7)
                            Divider(height: 1, color: colors.divider),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  static String _monthLabel(DateTime d) {
    const months = [
      'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
      'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь',
    ];
    return '${months[d.month - 1]} ${d.year}';
  }

  static String _shortDate(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '$dd.$mm';
  }
}

class _WorkerHeroCard extends StatelessWidget {
  const _WorkerHeroCard({
    required this.worker,
    required this.monthLabel,
    required this.accent,
    required this.serviceAccent,
  });

  final AttendanceAnalyticsWorker worker;
  final String monthLabel;
  final AttendanceWorkerAccent accent;
  final AppServiceAccent serviceAccent;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return AttendanceAnalyticsCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: accent.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: accent.icon.withValues(alpha: 0.2)),
                ),
                alignment: Alignment.center,
                child: Text(
                  attendanceWorkerInitials(worker.displayName),
                  style: AppTextStyle.base(22, color: accent.icon, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      worker.displayName,
                      style: AppTextStyle.base(22, color: colors.textColor, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(worker.username, style: AppTextStyle.base(14, color: colors.subTextColor)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: serviceAccent.soft,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        monthLabel,
                        style: AppTextStyle.base(12, color: serviceAccent.icon, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: serviceAccent.soft.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(AppIcons.schedule.icon, color: serviceAccent.icon, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        worker.totalHoursLabel,
                        style: AppTextStyle.base(24, color: colors.textColor, fontWeight: FontWeight.w800),
                      ),
                      Text(
                        'отработано за месяц',
                        style: AppTextStyle.base(13, color: colors.subTextColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthMetricsGrid extends StatelessWidget {
  const _MonthMetricsGrid({required this.worker});

  final AttendanceAnalyticsWorker worker;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final yellow = attendanceYellowAccent(colors);
    final accent = attendanceServiceAccent(colors);

    return Row(
      children: [
        Expanded(
          child: _MetricTile(
            label: 'Смены',
            value: '${worker.daysWorked}',
            icon: AppIcons.eventAvailable.icon,
            tint: accent.icon,
            bg: accent.soft,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MetricTile(
            label: 'Опоздания',
            value: '${worker.lateDays}',
            icon: AppIcons.accessTime.icon,
            tint: yellow.icon,
            bg: yellow.surface,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MetricTile(
            label: 'Пропуски',
            value: '${worker.missedDays}',
            icon: AppIcons.eventBusy.icon,
            tint: colors.destructive,
            bg: colors.functionalSoftRed,
          ),
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.tint,
    required this.bg,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color tint;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AttendanceAnalyticsCard(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AttendanceMetricIcon(icon: icon, tint: tint, bg: bg),
          const SizedBox(height: 12),
          Text(value, style: AppTextStyle.base(20, color: colors.textColor, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label, style: AppTextStyle.base(12, color: colors.subTextColor)),
        ],
      ),
    );
  }
}

class _PayrollPreviewCard extends StatelessWidget {
  const _PayrollPreviewCard({required this.payroll});

  final AttendanceWorkerPayroll payroll;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = attendanceServiceAccent(colors);
    final yellow = attendanceYellowAccent(colors);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AttendanceAnalyticsSectionHeader(
          title: 'Зарплата',
          subtitle: 'Расчёт за период',
        ),
        const SizedBox(height: 12),
        AttendanceAnalyticsCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _PayRow(label: 'Оклад', value: attendanceFormatMoney(payroll.baseSalary)),
              if (payroll.totalDeductions > 0) ...[
                const SizedBox(height: 8),
                _PayRow(
                  label: 'Списания',
                  value: '−${attendanceFormatMoney(payroll.totalDeductions)}',
                  valueColor: yellow.icon,
                ),
              ],
              if (payroll.totalBonuses > 0) ...[
                const SizedBox(height: 8),
                _PayRow(
                  label: 'Доплаты',
                  value: '+${attendanceFormatMoney(payroll.totalBonuses)}',
                  valueColor: accent.icon,
                ),
              ],
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              _PayRow(
                label: 'К выплате',
                value: attendanceFormatMoney(payroll.netPay),
                valueColor: accent.icon,
                bold: true,
              ),
              if (payroll.lines.isNotEmpty) ...[
                const SizedBox(height: 14),
                for (final line in payroll.lines)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                line.label,
                                style: AppTextStyle.base(13, color: colors.textColor, fontWeight: FontWeight.w600),
                              ),
                              if (line.detail != null)
                                Text(line.detail!, style: AppTextStyle.base(11, color: colors.subTextColor)),
                            ],
                          ),
                        ),
                        Text(
                          attendanceFormatMoneySigned(
                            line.amount,
                            isBonus: line.kind == AttendancePayrollLineKind.bonus,
                          ),
                          style: AppTextStyle.base(
                            13,
                            color: line.kind == AttendancePayrollLineKind.bonus
                                ? accent.icon
                                : line.kind == AttendancePayrollLineKind.deduction
                                    ? yellow.icon
                                    : colors.textColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _PayRow extends StatelessWidget {
  const _PayRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.bold = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTextStyle.base(
              bold ? 15 : 14,
              color: bold ? colors.textColor : colors.subTextColor,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: AppTextStyle.base(
            bold ? 18 : 14,
            color: valueColor ?? colors.textColor,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _PunchHistoryRow extends StatelessWidget {
  const _PunchHistoryRow({required this.record});

  final AttendancePunchRecord record;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = attendanceServiceAccent(colors);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: record.cancelled ? colors.surfaceMuted : accent.soft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              record.cancelled ? AppIcons.closeRounded.icon : AppIcons.accessTime.icon,
              size: 18,
              color: record.cancelled ? colors.subTextColor : accent.icon,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${record.formattedAt} · ${record.type.labelRu}',
                  style: AppTextStyle.base(
                    14,
                    color: record.cancelled ? colors.subTextColor : colors.textColor,
                    fontWeight: FontWeight.w700,
                  ).copyWith(
                    decoration: record.cancelled ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (record.cancelComment != null)
                  Text(record.cancelComment!, style: AppTextStyle.base(12, color: colors.subTextColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
