import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/feature/_attendance_/attendance_analytics/data/models/attendance_analytics_models.dart';
import 'package:clover/feature/_attendance_/attendance_analytics/presentation/widget/attendance_analytics_ui.dart';
import 'package:flutter/material.dart';

/// Крупная карточка: отметился работник в этот день или нет.
class AttendanceDayPresenceBanner extends StatelessWidget {
  const AttendanceDayPresenceBanner({
    super.key,
    required this.record,
    this.highlightToday = false,
    this.compact = false,
  });

  final AttendanceWorkerDayRecord record;
  final bool highlightToday;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = attendanceStatusAccent(colors, record.status);
    final surface = attendanceStatusSurface(colors, record.status);
    final isAbsent = record.status == AttendanceDayStatus.absent;
    final isOff = record.status == AttendanceDayStatus.off;
    final isExcused = record.status == AttendanceDayStatus.excused;

    return AttendanceAnalyticsCard(
      padding: EdgeInsets.all(compact ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: compact ? 40 : 48,
                height: compact ? 40 : 48,
                decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(compact ? 12 : 14)),
                child: Icon(
                  isAbsent ? AppIcons.closeRounded.icon : attendanceStatusIcon(record.status),
                  color: accent,
                  size: compact ? 20 : 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatDate(record.date),
                      style: AppTextStyle.base(12, color: colors.subTextColor, fontWeight: FontWeight.w600),
                    ),
                    if (highlightToday) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Сегодня',
                        style: AppTextStyle.base(11, color: colors.functionalSoftBlueIcon, fontWeight: FontWeight.w700),
                      ),
                    ],
                    const SizedBox(height: 2),
                    Text(
                      record.presenceHeadline,
                      style: AppTextStyle.base(compact ? 16 : 18, color: colors.textColor, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      record.presenceSummary,
                      style: AppTextStyle.base(13, color: colors.subTextColor),
                    ),
                  ],
                ),
              ),
              AttendanceStatusBadge(status: record.status, compact: true),
            ],
          ),
          if (!isOff && !isAbsent && !isExcused && record.totalMinutes > 0) ...[
            const SizedBox(height: 10),
            Text(
              'Итого ${record.totalLabel}',
              style: AppTextStyle.base(13, color: colors.textColor, fontWeight: FontWeight.w700),
            ),
          ],
          if (record.punches.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...record.punches.map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(AppIcons.accessTime.icon, size: 14, color: accent),
                    const SizedBox(width: 6),
                    Text(
                      p.timeLabel,
                      style: AppTextStyle.base(13, color: colors.textColor, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 8),
                    Text(p.label, style: AppTextStyle.base(13, color: colors.subTextColor)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _formatDate(DateTime d) {
    const weekdays = ['пн', 'вт', 'ср', 'чт', 'пт', 'сб', 'вс'];
    const months = [
      'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
      'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря',
    ];
    return '${d.day} ${months[d.month - 1]}, ${weekdays[d.weekday - 1]}';
  }
}
