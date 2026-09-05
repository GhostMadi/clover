import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/feature/_attendance_/attendance_analytics/data/attendance_analytics.dart';
import 'package:clover/feature/_attendance_/attendance_analytics/data/models/attendance_analytics_models.dart';
import 'package:clover/feature/_attendance_/attendance_analytics/presentation/widget/attendance_analytics_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Горизонтальный календарь по неделям (~100 px), свайп влево/вправо.
class AttendanceMiniCalendar extends StatefulWidget {
  const AttendanceMiniCalendar({
    super.key,
    required this.selectedDay,
    required this.daysByKey,
    required this.onDaySelected,
  });

  final DateTime selectedDay;
  final Map<DateTime, AttendanceWorkerDayRecord> daysByKey;
  final ValueChanged<DateTime> onDaySelected;

  static const double stripHeight = 100;

  @override
  State<AttendanceMiniCalendar> createState() => _AttendanceMiniCalendarState();
}

class _AttendanceMiniCalendarState extends State<AttendanceMiniCalendar> {
  static const _weekdayLabels = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
  static const _monthShort = [
    'янв',
    'фев',
    'мар',
    'апр',
    'май',
    'июн',
    'июл',
    'авг',
    'сен',
    'окт',
    'ноя',
    'дек',
  ];

  late PageController _pageController;
  late List<DateTime> _weekStarts;
  int _pageIndex = 0;

  static DateTime _dayKey(DateTime d) => DateTime(d.year, d.month, d.day);

  static DateTime _mondayOfWeek(DateTime day) {
    final key = _dayKey(day);
    return key.subtract(Duration(days: key.weekday - 1));
  }

  List<DateTime> _buildWeekStarts(DateTime anchor) {
    final today = AttendanceAnalytics.today;
    final monthStart = DateTime(anchor.year, anchor.month, 1);
    final monthEnd = DateTime(anchor.year, anchor.month + 1, 0);

    var weekStart = _mondayOfWeek(monthStart);
    final weeks = <DateTime>[];

    while (!weekStart.isAfter(monthEnd)) {
      final weekEnd = weekStart.add(const Duration(days: 6));
      final touchesMonth = !weekEnd.isBefore(monthStart) && !weekStart.isAfter(monthEnd);
      final hasPastOrToday = !weekStart.isAfter(today);
      if (touchesMonth && hasPastOrToday) {
        weeks.add(weekStart);
      }
      weekStart = weekStart.add(const Duration(days: 7));
    }

    if (weeks.isEmpty) {
      weeks.add(_mondayOfWeek(today));
    }
    return weeks;
  }

  int _indexForDay(DateTime day) {
    final monday = _mondayOfWeek(day);
    final idx = _weekStarts.indexWhere((w) => _dayKey(w) == _dayKey(monday));
    return idx >= 0 ? idx : 0;
  }

  @override
  void initState() {
    super.initState();
    _weekStarts = _buildWeekStarts(widget.selectedDay);
    _pageIndex = _indexForDay(widget.selectedDay);
    _pageController = PageController(initialPage: _pageIndex);
  }

  @override
  void didUpdateWidget(covariant AttendanceMiniCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final weeks = _buildWeekStarts(widget.selectedDay);
    if (weeks.length != _weekStarts.length ||
        weeks.any((w) => !_weekStarts.any((x) => _dayKey(x) == _dayKey(w)))) {
      _weekStarts = weeks;
    }
    final target = _indexForDay(widget.selectedDay);
    if (target != _pageIndex && _pageController.hasClients) {
      _pageIndex = target;
      _pageController.animateToPage(
        target,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goWeek(int delta) {
    final next = (_pageIndex + delta).clamp(0, _weekStarts.length - 1);
    if (next == _pageIndex) return;
    HapticFeedback.selectionClick();
    _pageController.animateToPage(
      next,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  String _weekLabel(DateTime weekStart) {
    final weekEnd = weekStart.add(const Duration(days: 6));
    final s = '${weekStart.day} ${_monthShort[weekStart.month - 1]}';
    if (weekStart.month == weekEnd.month) {
      return '$s – ${weekEnd.day} ${_monthShort[weekEnd.month - 1]}';
    }
    return '$s – ${weekEnd.day} ${_monthShort[weekEnd.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final today = AttendanceAnalytics.today;
    final selectedKey = _dayKey(widget.selectedDay);
    final canPrev = _pageIndex > 0;
    final canNext = _pageIndex < _weekStarts.length - 1;

    return AttendanceAnalyticsCard(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _WeekNavButton(icon: AppIcons.chevronLeft.icon, enabled: canPrev, onTap: () => _goWeek(-1)),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      _weekLabel(_weekStarts[_pageIndex]),
                      textAlign: TextAlign.center,
                      style: AppTextStyle.base(14, color: colors.textColor, fontWeight: FontWeight.w700),
                    ),
                    Text('Листайте по неделям', style: AppTextStyle.base(11, color: colors.subTextColor)),
                  ],
                ),
              ),
              _WeekNavButton(icon: AppIcons.chevronRight.icon, enabled: canNext, onTap: () => _goWeek(1)),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: AttendanceMiniCalendar.stripHeight,
            child: PageView.builder(
              controller: _pageController,
              itemCount: _weekStarts.length,
              onPageChanged: (index) {
                HapticFeedback.selectionClick();
                setState(() => _pageIndex = index);
              },
              itemBuilder: (context, pageIndex) {
                final weekStart = _weekStarts[pageIndex];
                return Row(
                  children: [
                    for (var i = 0; i < 7; i++)
                      Expanded(
                        child: _WeekDayCell(
                          day: weekStart.add(Duration(days: i)),
                          focusMonth: weekStart.month,
                          selectedKey: selectedKey,
                          today: today,
                          record: widget.daysByKey[_dayKey(weekStart.add(Duration(days: i)))],
                          onDaySelected: widget.onDaySelected,
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekNavButton extends StatelessWidget {
  const _WeekNavButton({required this.icon, required this.enabled, required this.onTap});

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.35,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 18, color: context.colors.textColor),
        ),
      ),
    );
  }
}

class _WeekDayCell extends StatelessWidget {
  const _WeekDayCell({
    required this.day,
    required this.focusMonth,
    required this.selectedKey,
    required this.today,
    required this.record,
    required this.onDaySelected,
  });

  final DateTime day;
  final int focusMonth;
  final DateTime selectedKey;
  final DateTime today;
  final AttendanceWorkerDayRecord? record;
  final ValueChanged<DateTime> onDaySelected;

  static DateTime _dayKey(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final key = _dayKey(day);
    final selected = key == selectedKey;
    final isToday = key == today;
    final isFuture = key.isAfter(today);
    final status = record?.status;
    final inMonth = day.month == focusMonth;
    final hasWorkStatus = status != null &&
        status != AttendanceDayStatus.off &&
        status != AttendanceDayStatus.excused &&
        !isFuture;
    final accent = hasWorkStatus ? attendanceStatusAccent(colors, status) : colors.iconMuted;

    Color bg = colors.pageBackground;
    if (selected) {
      bg = colors.functionalSoftBlueIcon;
    } else if (isToday) {
      bg = colors.infoSoft;
    }

    Color textColor;
    if (selected) {
      textColor = colors.textInverse;
    } else if (isFuture) {
      textColor = colors.iconMuted;
    } else if (!inMonth) {
      textColor = colors.subTextColor.withValues(alpha: 0.55);
    } else {
      textColor = colors.textColor;
    }

    final weekdayLabel = _AttendanceMiniCalendarState._weekdayLabels[day.weekday - 1];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: isFuture
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  onDaySelected(key);
                },
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: AttendanceMiniCalendar.stripHeight,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
              border: isToday && !selected ? Border.all(color: colors.functionalSoftBlueIcon.withValues(alpha: 0.45)) : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  weekdayLabel,
                  style: AppTextStyle.base(
                    10,
                    color: selected ? textColor.withValues(alpha: 0.85) : colors.subTextColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${day.day}',
                  style: AppTextStyle.base(16, color: textColor, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                if (hasWorkStatus)
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: selected ? colors.textInverse : accent,
                      shape: BoxShape.circle,
                    ),
                  )
                else if (isFuture)
                  Text('—', style: AppTextStyle.base(10, color: colors.iconMuted))
                else
                  Text(
                    status == AttendanceDayStatus.off ? '·' : '—',
                    style: AppTextStyle.base(12, color: colors.iconMuted),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
