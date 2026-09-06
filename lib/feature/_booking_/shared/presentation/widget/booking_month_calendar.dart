import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/feature/_booking_/booking_list/data/booking_host_inbox.dart';
import 'package:clover/feature/_booking_/shared/presentation/widget/booking_service_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Компактный месячный календарь: точки на днях с записями, выбор дня.
class BookingMonthCalendar extends StatefulWidget {
  const BookingMonthCalendar({
    super.key,
    required this.selectedDay,
    required this.countsByDay,
    required this.onDaySelected,
    this.focusedMonth,
  });

  final DateTime selectedDay;
  final Map<DateTime, int> countsByDay;
  final ValueChanged<DateTime> onDaySelected;

  /// Месяц при первом показе; дальше пользователь листает локально.
  final DateTime? focusedMonth;

  @override
  State<BookingMonthCalendar> createState() => _BookingMonthCalendarState();
}

class _BookingMonthCalendarState extends State<BookingMonthCalendar> {
  static const _weekdayLabels = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
  static const _monthLabels = [
    'Январь',
    'Февраль',
    'Март',
    'Апрель',
    'Май',
    'Июнь',
    'Июль',
    'Август',
    'Сентябрь',
    'Октябрь',
    'Ноябрь',
    'Декабрь',
  ];

  late DateTime _focusedMonth;

  @override
  void initState() {
    super.initState();
    _focusedMonth = _monthStart(widget.focusedMonth ?? widget.selectedDay);
  }

  @override
  void didUpdateWidget(BookingMonthCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final selectedMonth = _monthStart(widget.selectedDay);
    if (selectedMonth.year != _focusedMonth.year || selectedMonth.month != _focusedMonth.month) {
      _focusedMonth = selectedMonth;
    }
  }

  DateTime _monthStart(DateTime value) => DateTime(value.year, value.month);

  void _shiftMonth(int delta) {
    HapticFeedback.selectionClick();
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + delta);
    });
  }

  @override
  Widget build(BuildContext context) {
    final today = BookingHostInbox.dayKey(DateTime.now());
    final selectedKey = BookingHostInbox.dayKey(widget.selectedDay);
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final daysInMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final leadingEmpty = firstDay.weekday - 1;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: context.colors.border.withValues(alpha: 0.55)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  _MonthNavButton(icon: AppIcons.chevronLeft.icon, onTap: () => _shiftMonth(-1)),
                  Expanded(
                    child: Text(
                      '${_monthLabels[_focusedMonth.month - 1]} ${_focusedMonth.year}',
                      textAlign: TextAlign.center,
                      style: AppTextStyle.base(15, color: context.colors.textColor, fontWeight: FontWeight.w800),
                    ),
                  ),
                  _MonthNavButton(icon: AppIcons.chevronRight.icon, onTap: () => _shiftMonth(1)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  for (final label in _weekdayLabels)
                    Expanded(
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: AppTextStyle.base(11, color: context.colors.subTextColor, fontWeight: FontWeight.w700),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                  childAspectRatio: 1.05,
                ),
                itemCount: leadingEmpty + daysInMonth,
                itemBuilder: (context, index) {
                  if (index < leadingEmpty) return const SizedBox.shrink();

                  final dayNumber = index - leadingEmpty + 1;
                  final day = DateTime(_focusedMonth.year, _focusedMonth.month, dayNumber);
                  final key = BookingHostInbox.dayKey(day);
                  final selected = key == selectedKey;
                  final isToday = key == today;
                  final count = widget.countsByDay[key] ?? 0;

                  return _DayCell(
                    day: dayNumber,
                    selected: selected,
                    isToday: isToday,
                    count: count,
                    onTap: () {
                      if (selected) return;
                      HapticFeedback.selectionClick();
                      widget.onDaySelected(key);
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MonthNavButton extends StatelessWidget {
  const _MonthNavButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.surfaceSoft,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(icon, size: 18, color: context.colors.textColor),
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
    required this.count,
    required this.onTap,
  });

  final int day;
  final bool selected;
  final bool isToday;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = bookingServiceAccent(context.colors);
    final textColor = selected
        ? accent.ctaForeground
        : isToday
            ? accent.icon
            : context.colors.textColor;

    return Material(
      color: selected ? accent.cta : context.colors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: isToday && !selected ? Border.all(color: accent.icon, width: 1.5) : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$day',
                style: AppTextStyle.base(14, color: textColor, fontWeight: FontWeight.w700),
              ),
              SizedBox(
                height: 6,
                child: count > 0
                    ? Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: selected ? accent.ctaForeground.withValues(alpha: 0.85) : accent.icon,
                          shape: BoxShape.circle,
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
