import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/feature/_attendance_/attendance_analytics/data/models/attendance_analytics_models.dart';
import 'package:clover/feature/_attendance_/attendance_analytics/presentation/widget/attendance_analytics_ui.dart';
import 'package:flutter/material.dart';

class AttendanceDayDetailCard extends StatelessWidget {
  const AttendanceDayDetailCard({super.key, required this.record});

  final AttendanceWorkerDayRecord record;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = attendanceStatusAccent(colors, record.status);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AttendanceAnalyticsSectionHeader(
          title: 'День',
          subtitle: _formatDate(record.date),
          trailing: AttendanceStatusBadge(status: record.status),
        ),
        const SizedBox(height: 12),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: AttendanceAnalyticsCard(
            key: ValueKey(record.date),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    AttendanceMetricIcon(
                      icon: attendanceStatusIcon(record.status),
                      tint: accent,
                      bg: attendanceStatusSurface(colors, record.status),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            record.totalLabel,
                            style: AppTextStyle.base(22, color: colors.textColor, fontWeight: FontWeight.w800),
                          ),
                          Text(
                            switch (record.status) {
                              AttendanceDayStatus.off => 'Выходной',
                              AttendanceDayStatus.excused => 'Оформленное отсутствие',
                              AttendanceDayStatus.absent => 'Пропуск',
                              _ => 'Отработано за день',
                            },
                            style: AppTextStyle.base(13, color: colors.subTextColor),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (record.punches.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Text(
                    'Отметки',
                    style: AppTextStyle.base(13, color: colors.subTextColor, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  _PunchTimeline(punches: record.punches, accent: accent),
                ] else ...[
                  const SizedBox(height: 16),
                  _EmptyDayMessage(status: record.status),
                ],
              ],
            ),
          ),
        ),
      ],
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

class _PunchTimeline extends StatelessWidget {
  const _PunchTimeline({required this.punches, required this.accent});

  final List<AttendanceDayPunch> punches;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      children: [
        for (var i = 0; i < punches.length; i++) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                  ),
                  if (i < punches.length - 1)
                    Container(width: 2, height: 36, color: colors.borderSoft),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: colors.pageBackground,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(AppIcons.accessTime.icon, size: 16, color: accent),
                        const SizedBox(width: 8),
                        Text(
                          punches[i].timeLabel,
                          style: AppTextStyle.base(14, color: colors.textColor, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            punches[i].label,
                            style: AppTextStyle.base(14, color: colors.subTextColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _EmptyDayMessage extends StatelessWidget {
  const _EmptyDayMessage({required this.status});

  final AttendanceDayStatus status;

  @override
  Widget build(BuildContext context) {
    final (icon, text) = switch (status) {
      AttendanceDayStatus.absent => (AppIcons.eventBusy.icon, 'Отметок не было'),
      AttendanceDayStatus.excused => (AppIcons.eventAvailable.icon, 'Отсутствие оформлено — не пропуск'),
      AttendanceDayStatus.off => (AppIcons.eventAvailable.icon, 'Выходной день'),
      _ => (AppIcons.infoOutline.icon, 'Нет данных'),
    };

    return Row(
      children: [
        Icon(icon, size: 18, color: context.colors.iconMuted),
        const SizedBox(width: 8),
        Text(text, style: AppTextStyle.base(14, color: context.colors.subTextColor)),
      ],
    );
  }
}
