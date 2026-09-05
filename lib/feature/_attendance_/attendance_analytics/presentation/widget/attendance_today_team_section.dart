import 'package:auto_route/auto_route.dart';
import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/router/app_router.gr.dart';
import 'package:clover/feature/_attendance_/attendance_analytics/data/attendance_analytics.dart';
import 'package:clover/feature/_attendance_/attendance_analytics/data/models/attendance_analytics_models.dart';
import 'package:clover/feature/_attendance_/attendance_analytics/presentation/widget/attendance_analytics_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Кто отметился сегодня — обзор по всей команде за один день.
class AttendanceTodayTeamSection extends StatelessWidget {
  const AttendanceTodayTeamSection({
    super.key,
    required this.workers,
    required this.workplaceId,
  });

  final List<AttendanceAnalyticsWorker> workers;
  final String workplaceId;

  @override
  Widget build(BuildContext context) {
    if (workers.isEmpty) return const SizedBox.shrink();

    final today = AttendanceAnalytics.today;
    final rows = <_TodayRow>[];

    for (final worker in workers) {
      final record = worker.daysByKey[today];
      if (record == null) continue;
      rows.add(_TodayRow(worker: worker, record: record));
    }

    if (rows.isEmpty) return const SizedBox.shrink();

    final marked = rows.where((r) => r.record.hasPunches).length;
    final absent = rows.where((r) => r.record.status == AttendanceDayStatus.absent).length;
    final excused = rows.where((r) => r.record.status == AttendanceDayStatus.excused).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AttendanceAnalyticsSectionHeader(
          title: 'Сегодня',
          subtitle: [
            'Кто отметился · $marked из ${rows.length}',
            if (absent > 0) '$absent не пришли',
            if (excused > 0) '$excused оформлено',
          ].join(' · '),
        ),
        const SizedBox(height: 12),
        AttendanceAnalyticsCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                _TodayWorkerRow(
                  row: rows[i],
                  onTap: () {
                    HapticFeedback.lightImpact();
                    context.router.push(
                      AttendanceWorkerAnalyticsRoute(
                        workplaceId: workplaceId,
                        workerId: rows[i].worker.id,
                      ),
                    );
                  },
                ),
                if (i < rows.length - 1)
                  Divider(height: 1, indent: 56, color: context.colors.divider),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _TodayRow {
  const _TodayRow({required this.worker, required this.record});

  final AttendanceAnalyticsWorker worker;
  final AttendanceWorkerDayRecord record;
}

class _TodayWorkerRow extends StatelessWidget {
  const _TodayWorkerRow({required this.row, required this.onTap});

  final _TodayRow row;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final record = row.record;
    final accent = attendanceWorkerAccent(colors, attendanceWorkerAccentSeed(row.worker.id));
    final statusAccent = attendanceStatusAccent(colors, record.status);
    final isAbsent = record.status == AttendanceDayStatus.absent;
    final isOff = record.status == AttendanceDayStatus.off;
    final isExcused = record.status == AttendanceDayStatus.excused;

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: accent.surface,
                child: Text(
                  attendanceWorkerInitials(row.worker.displayName),
                  style: AppTextStyle.base(11, color: accent.icon, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.worker.displayName,
                      style: AppTextStyle.base(15, color: colors.textColor, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      isOff
                          ? 'Выходной'
                          : isExcused
                              ? 'Отсутствие оформлено'
                              : isAbsent
                                  ? 'Не отметился'
                                  : record.presenceSummary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyle.base(13, color: colors.subTextColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (!isOff)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: attendanceStatusSurface(colors, record.status),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isAbsent ? AppIcons.closeRounded.icon : AppIcons.checkRounded.icon,
                        size: 14,
                        color: statusAccent,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        record.status.shortLabelRu,
                        style: AppTextStyle.base(11, color: statusAccent, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              const SizedBox(width: 4),
              Icon(AppIcons.chevronRight.icon, size: 16, color: colors.iconMuted),
            ],
          ),
        ),
      ),
    );
  }
}
