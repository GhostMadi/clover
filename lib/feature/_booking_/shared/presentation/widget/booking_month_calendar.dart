import 'package:clover/core/extension/context.dart';
import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_bottom_sheet.dart';
import 'package:clover/feature/_booking_/booking_list/data/booking_host_inbox.dart';
import 'package:clover/feature/_booking_/shared/presentation/widget/booking_service_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Выбор дня в шторке: лента дней остаётся быстрым UX, месяц — для прыжка.
abstract final class BookingMonthCalendarSheet {
  static Future<DateTime?> show(
    BuildContext context, {
    required DateTime selectedDay,
    required Map<DateTime, int> countsByDay,
  }) {
    return AppBottomSheet.show<DateTime>(
      context: context,
      title: context.l10n.booking_day,
      upperCaseTitle: false,
      showCloseButton: true,
      service: kBookingService,
      contentPadding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
      contentBottomSpacing: 8,
      content: Builder(
        builder: (sheetContext) => BookingMonthCalendar(
          selectedDay: selectedDay,
          countsByDay: countsByDay,
          onDaySelected: (day) => Navigator.of(sheetContext).pop(day),
        ),
      ),
    );
  }
}

/// Компактная месячная сетка (для шторки): круг выбора, точки на днях с записями.
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
  final DateTime? focusedMonth;

  @override
  State<BookingMonthCalendar> createState() => _BookingMonthCalendarState();
}

class _BookingMonthCalendarState extends State<BookingMonthCalendar> {
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
    final colors = context.colors;
    final accent = bookingServiceAccent(colors);
    final today = BookingHostInbox.dayKey(DateTime.now());
    final selectedKey = BookingHostInbox.dayKey(widget.selectedDay);
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final daysInMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final leadingEmpty = firstDay.weekday - 1;
    final totalCells = leadingEmpty + daysInMonth;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _MonthNavButton(icon: AppIcons.chevronLeft.icon, onTap: () => _shiftMonth(-1)),
            Expanded(
              child: Text(
                '${context.dateFormat.monthName(_focusedMonth.month)} ${_focusedMonth.year}',
                textAlign: TextAlign.center,
                style: AppTextStyle.base(
                  17,
                  color: colors.textColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            _MonthNavButton(icon: AppIcons.chevronRight.icon, onTap: () => _shiftMonth(1)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            for (final label in context.dateFormat.weekdayShortLabels())
              Expanded(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: AppTextStyle.base(
                    12,
                    color: colors.subTextColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 2,
            crossAxisSpacing: 2,
            childAspectRatio: 1,
          ),
          itemCount: totalCells,
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
              hasBookings: count > 0,
              accent: accent,
              onTap: () {
                HapticFeedback.selectionClick();
                widget.onDaySelected(key);
              },
            );
          },
        ),
      ],
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
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, size: 20, color: context.colors.textColor),
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
    required this.hasBookings,
    required this.accent,
    required this.onTap,
  });

  final int day;
  final bool selected;
  final bool isToday;
  final bool hasBookings;
  final AppServiceAccent accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final Color circleBg;
    final Color textColor;
    if (selected) {
      circleBg = accent.cta;
      textColor = accent.ctaForeground;
    } else if (isToday) {
      circleBg = accent.soft;
      textColor = accent.icon;
    } else {
      circleBg = colors.surface;
      textColor = colors.textColor;
    }

    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected || isToday ? circleBg : null,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$day',
              style: AppTextStyle.base(
                15,
                color: textColor,
                fontWeight: selected || isToday ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          SizedBox(
            height: 5,
            child: hasBookings
                ? Center(
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: selected
                            ? accent.ctaForeground.withValues(alpha: 0.9)
                            : accent.icon.withValues(alpha: 0.8),
                        shape: BoxShape.circle,
                      ),
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
  }
}
