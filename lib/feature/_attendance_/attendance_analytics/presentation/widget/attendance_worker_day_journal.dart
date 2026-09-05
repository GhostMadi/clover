import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/feature/_attendance_/attendance_analytics/data/models/attendance_analytics_models.dart';
import 'package:clover/feature/_attendance_/attendance_analytics/presentation/widget/attendance_analytics_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Список рабочих дней — быстрый обзор «пришёл / не отметился» без календаря.
class AttendanceWorkerDayJournal extends StatelessWidget {
  const AttendanceWorkerDayJournal({
    super.key,
    required this.daysByKey,
    required this.selectedDay,
    required this.onDaySelected,
    this.maxItems = 14,
  });

  final Map<DateTime, AttendanceWorkerDayRecord> daysByKey;
  final DateTime selectedDay;
  final ValueChanged<DateTime> onDaySelected;
  final int maxItems;

  static DateTime _dayKey(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  Widget build(BuildContext context) {
    final today = _dayKey(DateTime.now());
    final entries = daysByKey.entries
        .where((e) => e.value.isWorkday && !e.key.isAfter(today))
        .toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    if (entries.isEmpty) return const SizedBox.shrink();

    final visible = entries.take(maxItems).toList();
    final selectedKey = _dayKey(selectedDay);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AttendanceAnalyticsSectionHeader(
          title: 'Журнал',
          subtitle: 'Быстрый обзор по дням — нажмите на строку',
        ),
        const SizedBox(height: 12),
        AttendanceAnalyticsCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < visible.length; i++) ...[
                _JournalRow(
                  record: visible[i].value,
                  selected: visible[i].key == selectedKey,
                  isToday: visible[i].key == today,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onDaySelected(visible[i].key);
                  },
                ),
                if (i < visible.length - 1)
                  Divider(height: 1, indent: 56, color: context.colors.divider),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _JournalRow extends StatelessWidget {
  const _JournalRow({
    required this.record,
    required this.selected,
    required this.isToday,
    required this.onTap,
  });

  final AttendanceWorkerDayRecord record;
  final bool selected;
  final bool isToday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = attendanceStatusAccent(colors, record.status);
    final isAbsent = record.status == AttendanceDayStatus.absent;

    return Material(
      color: selected ? colors.functionalSoftBlueIcon.withValues(alpha: 0.35) : null,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: attendanceStatusSurface(colors, record.status),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isAbsent ? AppIcons.closeRounded.icon : attendanceStatusIcon(record.status),
                  size: 18,
                  color: accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _formatDay(record.date),
                          style: AppTextStyle.base(15, color: colors.textColor, fontWeight: FontWeight.w700),
                        ),
                        if (isToday) ...[
                          const SizedBox(width: 6),
                          Text(
                            '· сегодня',
                            style: AppTextStyle.base(12, color: colors.functionalSoftBlueIcon, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      record.presenceSummary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyle.base(13, color: colors.subTextColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    record.status.shortLabelRu,
                    style: AppTextStyle.base(12, color: accent, fontWeight: FontWeight.w700),
                  ),
                  if (record.totalMinutes > 0)
                    Text(
                      record.totalLabel,
                      style: AppTextStyle.base(12, color: colors.subTextColor),
                    ),
                ],
              ),
              const SizedBox(width: 4),
              Icon(AppIcons.chevronRight.icon, size: 16, color: colors.iconMuted),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatDay(DateTime d) {
    const weekdays = ['пн', 'вт', 'ср', 'чт', 'пт', 'сб', 'вс'];
    const months = ['янв', 'фев', 'мар', 'апр', 'май', 'июн', 'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'];
    return '${d.day} ${months[d.month - 1]}, ${weekdays[d.weekday - 1]}';
  }
}
