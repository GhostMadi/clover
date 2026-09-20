import 'package:auto_route/auto_route.dart';
import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/router/app_router.gr.dart';
import 'package:clover/feature/_attendance_/attendance_analytics/data/attendance_analytics.dart';
import 'package:clover/feature/_attendance_/attendance_analytics/data/models/attendance_analytics_models.dart';
import 'package:clover/feature/_attendance_/attendance_analytics/presentation/widget/attendance_analytics_ui.dart';
import 'package:clover/feature/_attendance_/shared/presentation/widget/attendance_section_title.dart';
import 'package:clover/feature/_attendance_/shared/presentation/widget/attendance_service_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Кто отметился сегодня.
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
    final rows = <({AttendanceAnalyticsWorker worker, AttendanceWorkerDayRecord record})>[];
    for (final worker in workers) {
      final record = worker.daysByKey[today];
      if (record == null) continue;
      rows.add((worker: worker, record: record));
    }
    if (rows.isEmpty) return const SizedBox.shrink();

    final marked = rows.where((r) => r.record.hasPunches).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AttendanceSectionTitle('Сегодня · $marked / ${rows.length}'),
        const SizedBox(height: 8),
        for (final row in rows) ...[
          _TodayTile(
            name: row.worker.displayName,
            subtitle: _subtitle(row.record),
            status: row.record.status,
            onTap: () {
              HapticFeedback.selectionClick();
              context.router.push(
                AttendanceWorkerAnalyticsRoute(
                  workplaceId: workplaceId,
                  workerId: row.worker.id,
                ),
              );
            },
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  static String _subtitle(AttendanceWorkerDayRecord record) {
    return switch (record.status) {
      AttendanceDayStatus.off => 'Выходной',
      AttendanceDayStatus.excused => 'Оформлено',
      AttendanceDayStatus.absent => 'Не отметился',
      _ => record.presenceSummary,
    };
  }
}

class _TodayTile extends StatelessWidget {
  const _TodayTile({
    required this.name,
    required this.subtitle,
    required this.status,
    required this.onTap,
  });

  final String name;
  final String subtitle;
  final AttendanceDayStatus status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = attendanceServiceAccent(colors);
    final statusColor = attendanceStatusAccent(colors, status);

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.border.withValues(alpha: 0.55)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: accent.soft,
                  child: Icon(AppIcons.user.icon, color: accent.icon, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyle.base(15, color: colors.textColor, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyle.base(12, color: colors.subTextColor, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                Text(
                  status.shortLabelRu,
                  style: AppTextStyle.base(12, color: statusColor, fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 4),
                Icon(AppIcons.chevronRight.icon, size: 20, color: colors.iconMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
