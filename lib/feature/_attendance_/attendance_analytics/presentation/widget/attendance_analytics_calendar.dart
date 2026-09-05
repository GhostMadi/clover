import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/feature/_attendance_/attendance_analytics/data/models/attendance_analytics_models.dart';
import 'package:clover/feature/_attendance_/attendance_analytics/presentation/widget/attendance_analytics_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Календарь аналитики: цветные дни, часы, анимация выбора.
class AttendanceAnalyticsCalendar extends StatefulWidget {
  const AttendanceAnalyticsCalendar({
    super.key,
    required this.selectedDay,
    required this.daysByKey,
    required this.onDaySelected,
    this.focusedMonth,
    this.title = 'Календарь',
    this.compact = false,
  });

  final DateTime selectedDay;
  final Map<DateTime, AttendanceWorkerDayRecord> daysByKey;
  final ValueChanged<DateTime> onDaySelected;
  final DateTime? focusedMonth;
  final String title;

  /// Компактный режим: меньше высота, без легенды — для экрана работника.
  final bool compact;

  @override
  State<AttendanceAnalyticsCalendar> createState() => _AttendanceAnalyticsCalendarState();
}

class _AttendanceAnalyticsCalendarState extends State<AttendanceAnalyticsCalendar> {
  static const _weekdayLabels = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
  static const _monthLabels = [
    'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
    'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь',
  ];

  late DateTime _focusedMonth;

  @override
  void initState() {
    super.initState();
    _focusedMonth = _monthStart(widget.focusedMonth ?? widget.selectedDay);
  }

  @override
  void didUpdateWidget(covariant AttendanceAnalyticsCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_sameMonth(_focusedMonth, widget.selectedDay)) {
      _focusedMonth = _monthStart(widget.selectedDay);
    }
  }

  bool _sameMonth(DateTime a, DateTime b) => a.year == b.year && a.month == b.month;

  DateTime _monthStart(DateTime value) => DateTime(value.year, value.month);

  static DateTime _dayKey(DateTime value) => DateTime(value.year, value.month, value.day);

  void _shiftMonth(int delta) {
    HapticFeedback.selectionClick();
    setState(() => _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + delta));
  }

  @override
  Widget build(BuildContext context) {
    final today = _dayKey(DateTime.now());
    final selectedKey = _dayKey(widget.selectedDay);
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final daysInMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final leadingEmpty = firstDay.weekday - 1;
    final compact = widget.compact;

    final calendarBody = AttendanceAnalyticsCard(
      padding: EdgeInsets.fromLTRB(compact ? 8 : 12, compact ? 10 : 14, compact ? 8 : 12, compact ? 8 : 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _NavButton(
                icon: AppIcons.chevronLeft.icon,
                compact: compact,
                onTap: () => _shiftMonth(-1),
              ),
              Expanded(
                child: Text(
                  '${_monthLabels[_focusedMonth.month - 1]} ${_focusedMonth.year}',
                  textAlign: TextAlign.center,
                  style: AppTextStyle.base(
                    compact ? 14 : 16,
                    color: context.colors.textColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _NavButton(
                icon: AppIcons.chevronRight.icon,
                compact: compact,
                onTap: () => _shiftMonth(1),
              ),
            ],
          ),
          SizedBox(height: compact ? 8 : 12),
          Row(
            children: [
              for (final label in _weekdayLabels)
                Expanded(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: AppTextStyle.base(
                      compact ? 10 : 11,
                      color: context.colors.subTextColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: compact ? 4 : 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: compact ? 4 : 6,
              crossAxisSpacing: compact ? 4 : 6,
              childAspectRatio: compact ? 1.15 : 0.92,
            ),
            itemCount: leadingEmpty + daysInMonth,
            itemBuilder: (context, index) {
              if (index < leadingEmpty) return const SizedBox.shrink();

              final dayNumber = index - leadingEmpty + 1;
              final day = DateTime(_focusedMonth.year, _focusedMonth.month, dayNumber);
              final key = _dayKey(day);
              final record = widget.daysByKey[key];
              final selected = key == selectedKey;
              final isToday = key == today;
              final isFuture = key.isAfter(today);

              return _DayCell(
                day: dayNumber,
                selected: selected,
                isToday: isToday,
                isFuture: isFuture,
                status: record?.status,
                hoursLabel: compact || selected ? null : (record != null && record.totalMinutes > 0 ? record.totalLabel : null),
                compact: compact,
                onTap: isFuture
                    ? null
                    : () {
                        HapticFeedback.selectionClick();
                        widget.onDaySelected(key);
                      },
              );
            },
          ),
          if (!compact) ...[
            const SizedBox(height: 14),
            const Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                _LegendChip(status: AttendanceDayStatus.full, label: 'Полная'),
                _LegendChip(status: AttendanceDayStatus.late, label: 'Опозд.'),
                _LegendChip(status: AttendanceDayStatus.partial, label: 'Неполная'),
                _LegendChip(status: AttendanceDayStatus.absent, label: 'Пропуск'),
                _LegendChip(status: AttendanceDayStatus.excused, label: 'Оформлено'),
              ],
            ),
          ],
        ],
      ),
    );

    if (compact) return calendarBody;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AttendanceAnalyticsSectionHeader(
          title: widget.title,
          subtitle: 'Цвет = статус · ✓ отметился · ✗ не пришёл',
        ),
        const SizedBox(height: 12),
        calendarBody,
      ],
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.icon, required this.onTap, this.compact = false});

  final IconData icon;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 32.0 : 38.0;
    return Material(
      color: context.colors.surfaceMuted,
      borderRadius: BorderRadius.circular(compact ? 10 : 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(compact ? 10 : 12),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, size: compact ? 16 : 18, color: context.colors.textColor),
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.selected,
    required this.isToday,
    required this.isFuture,
    required this.status,
    required this.hoursLabel,
    required this.onTap,
    this.compact = false,
  });

  final int day;
  final bool selected;
  final bool isToday;
  final bool isFuture;
  final AttendanceDayStatus? status;
  final String? hoursLabel;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bg = isFuture ? colors.surfaceMuted : statusBackground(colors, status, selected);
    final fg = selected
        ? colors.textInverse
        : isFuture
            ? colors.iconMuted
            : isToday
                ? colors.functionalSoftBlueIcon
                : colors.textColor;

    return AnimatedScale(
      scale: selected && !compact ? 1.04 : 1,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutBack,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(compact ? 10 : 14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(compact ? 10 : 14),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(compact ? 10 : 14),
              border: isToday && !selected ? Border.all(color: colors.functionalSoftBlueIcon, width: compact ? 1.5 : 2) : null,
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: compact ? 2 : 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$day',
                    style: AppTextStyle.base(
                      compact ? 12 : 14,
                      color: fg,
                      fontWeight: selected || isToday ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                  if (hoursLabel != null && !selected) ...[
                    const SizedBox(height: 2),
                    Text(
                      hoursLabel!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyle.base(8, color: fg.withValues(alpha: 0.85), fontWeight: FontWeight.w600),
                    ),
                  ] else if (!isFuture && !selected && status != null && status != AttendanceDayStatus.off)
                    Padding(
                      padding: EdgeInsets.only(top: compact ? 1 : 3),
                      child: Icon(
                        status == AttendanceDayStatus.absent
                            ? AppIcons.closeRounded.icon
                            : AppIcons.checkRounded.icon,
                        size: compact ? 9 : 12,
                        color: selected ? fg : attendanceStatusAccent(colors, status!),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({required this.status, required this.label});

  final AttendanceDayStatus status;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: statusBackground(colors, status, false),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(attendanceStatusIcon(status), size: 12, color: attendanceStatusAccent(colors, status)),
          const SizedBox(width: 4),
          Text(label, style: AppTextStyle.base(11, color: colors.textColor, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
