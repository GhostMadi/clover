import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_date_picker.dart';
import 'package:clover/feature/_booking_/shared/presentation/widget/booking_service_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BookingAnalyticsPeriodPicker extends StatelessWidget {
  const BookingAnalyticsPeriodPicker({
    super.key,
    required this.start,
    required this.end,
    required this.onStartChanged,
    required this.onEndChanged,
    required this.onWeekPreset,
    required this.onMonthPreset,
  });

  final DateTime start;
  final DateTime end;
  final ValueChanged<DateTime> onStartChanged;
  final ValueChanged<DateTime> onEndChanged;
  final VoidCallback onWeekPreset;
  final VoidCallback onMonthPreset;

  bool get _isWeek {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(const Duration(days: 6));
    return _sameDay(end, today) && _sameDay(start, weekStart);
  }

  bool get _isMonth {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monthStart = DateTime(now.year, now.month, 1);
    return _sameDay(end, today) && _sameDay(start, monthStart);
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _PresetChip(
                label: 'Неделя',
                selected: _isWeek,
                onTap: onWeekPreset,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _PresetChip(
                label: 'Месяц',
                selected: _isMonth,
                onTap: onMonthPreset,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: AppDatePicker(
                label: 'С',
                hint: 'Начало',
                value: start,
                lastDate: end,
                service: kBookingService,
                onChanged: (value) {
                  onStartChanged(DateTime(value.year, value.month, value.day));
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AppDatePicker(
                label: 'По',
                hint: 'Конец',
                value: end,
                firstDate: start,
                service: kBookingService,
                onChanged: (value) {
                  onEndChanged(DateTime(value.year, value.month, value.day));
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = bookingServiceAccent(colors);

    return Material(
      color: selected ? accent.cta : colors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? accent.ctaBorder : colors.border.withValues(alpha: 0.65),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: AppTextStyle.base(
                14,
                color: selected ? accent.ctaForeground : colors.textColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
