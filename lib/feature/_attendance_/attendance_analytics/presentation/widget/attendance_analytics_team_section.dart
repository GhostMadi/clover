import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/feature/_attendance_/attendance_analytics/data/models/attendance_analytics_models.dart';
import 'package:clover/feature/_attendance_/attendance_analytics/presentation/widget/attendance_analytics_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AttendanceAnalyticsTeamSection extends StatelessWidget {
  const AttendanceAnalyticsTeamSection({
    super.key,
    required this.workers,
    required this.maxHours,
    required this.onWorkerTap,
  });

  final List<AttendanceAnalyticsWorker> workers;
  final double maxHours;
  final ValueChanged<AttendanceAnalyticsWorker> onWorkerTap;

  @override
  Widget build(BuildContext context) {
    if (workers.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AttendanceAnalyticsSectionHeader(
          title: 'Команда',
          subtitle: 'Сравнение и переход к календарю',
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: context.colors.functionalSoftBlue,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${workers.length}',
              style: AppTextStyle.base(12, color: context.colors.functionalSoftBlueIcon, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < workers.length; i++) ...[
          _WorkerRow(
            rank: i + 1,
            worker: workers[i],
            maxHours: maxHours,
            onTap: () => onWorkerTap(workers[i]),
          ),
          if (i < workers.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _WorkerRow extends StatefulWidget {
  const _WorkerRow({
    required this.rank,
    required this.worker,
    required this.maxHours,
    required this.onTap,
  });

  final int rank;
  final AttendanceAnalyticsWorker worker;
  final double maxHours;
  final VoidCallback onTap;

  @override
  State<_WorkerRow> createState() => _WorkerRowState();
}

class _WorkerRowState extends State<_WorkerRow> {
  bool _pressed = false;

  void _handleTap() {
    HapticFeedback.lightImpact();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = attendanceWorkerAccent(colors, widget.rank);
    final progress = widget.maxHours <= 0 ? 0.0 : (widget.worker.hoursValue / widget.maxHours).clamp(0.0, 1.0);
    final pct = (progress * 100).round();

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _handleTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1,
        duration: const Duration(milliseconds: 120),
        child: AttendanceAnalyticsCard(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: accent.surface,
                    child: Text(
                      attendanceWorkerInitials(widget.worker.displayName),
                      style: AppTextStyle.base(14, color: accent.icon, fontWeight: FontWeight.w800),
                    ),
                  ),
                  Positioned(
                    right: -4,
                    bottom: -2,
                    child: Container(
                      width: 20,
                      height: 20,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: accent.icon,
                        shape: BoxShape.circle,
                        border: Border.all(color: colors.surface, width: 2),
                      ),
                      child: Text(
                        '${widget.rank}',
                        style: AppTextStyle.base(10, color: colors.textInverse, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.worker.displayName,
                            style: AppTextStyle.base(16, color: colors.textColor, fontWeight: FontWeight.w700),
                          ),
                        ),
                        Text(
                          widget.worker.totalHoursLabel,
                          style: AppTextStyle.base(15, color: accent.icon, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                    Text(widget.worker.username, style: AppTextStyle.base(12, color: colors.subTextColor)),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: progress),
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, _) {
                          return LinearProgressIndicator(
                            value: value,
                            minHeight: 8,
                            backgroundColor: colors.surfaceMuted,
                            color: accent.icon,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          '$pct% от лидера',
                          style: AppTextStyle.base(11, color: colors.subTextColor),
                        ),
                        const Spacer(),
                        if (widget.worker.lateDays > 0)
                          _MiniChip(
                            label: '${widget.worker.lateDays} опозд.',
                            color: colors.functionalSoftYellow,
                            icon: AppIcons.accessTime.icon,
                          ),
                        if (widget.worker.missedDays > 0) ...[
                          const SizedBox(width: 4),
                          _MiniChip(
                            label: '${widget.worker.missedDays} проп.',
                            color: colors.functionalSoftRed,
                            icon: AppIcons.eventBusy.icon,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(AppIcons.chevronRight.icon, color: colors.iconMuted, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({required this.label, required this.color, required this.icon});

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: context.colors.textColor),
          const SizedBox(width: 3),
          Text(label, style: AppTextStyle.base(10, color: context.colors.textColor, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
