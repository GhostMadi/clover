import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/feature/_attendance_/attendance_analytics/data/models/attendance_analytics_models.dart';
import 'package:clover/feature/_attendance_/shared/presentation/widget/attendance_section_title.dart';
import 'package:clover/feature/_attendance_/shared/presentation/widget/attendance_service_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Список работников за период — тап → календарь.
class AttendanceAnalyticsTeamSection extends StatelessWidget {
  const AttendanceAnalyticsTeamSection({
    super.key,
    required this.workers,
    required this.onWorkerTap,
  });

  final List<AttendanceAnalyticsWorker> workers;
  final ValueChanged<AttendanceAnalyticsWorker> onWorkerTap;

  @override
  Widget build(BuildContext context) {
    if (workers.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AttendanceSectionTitle('Команда'),
        const SizedBox(height: 8),
        for (final worker in workers) ...[
          _WorkerTile(
            worker: worker,
            onTap: () {
              HapticFeedback.selectionClick();
              onWorkerTap(worker);
            },
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _WorkerTile extends StatelessWidget {
  const _WorkerTile({required this.worker, required this.onTap});

  final AttendanceAnalyticsWorker worker;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = attendanceServiceAccent(colors);
    final username = worker.username.trim();
    final lateMiss = [
      if (worker.lateDays > 0) '${worker.lateDays} опозд.',
      if (worker.missedDays > 0) '${worker.missedDays} проп.',
    ].join(' · ');
    final subtitle = [
      if (username.isNotEmpty) (username.startsWith('@') ? username : '@$username'),
      if (lateMiss.isNotEmpty) lateMiss,
    ].join(' · ');

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
                        worker.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyle.base(15, color: colors.textColor, fontWeight: FontWeight.w700),
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyle.base(12, color: colors.subTextColor, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ],
                  ),
                ),
                Text(
                  worker.totalHoursLabel,
                  style: AppTextStyle.base(15, color: accent.icon, fontWeight: FontWeight.w800),
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
