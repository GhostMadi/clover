import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_date_picker.dart';
import 'package:clover/feature/_booking_/shared/presentation/widget/booking_service_ui.dart';
import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Период',
          style: AppTextStyle.base(14, color: context.colors.subTextColor, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _PresetChip(label: 'Неделя', onTap: onWeekPreset),
            _PresetChip(label: 'Месяц', onTap: onMonthPreset),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: AppDatePicker(
                label: 'С',
                hint: 'Дата начала',
                value: start,
                lastDate: end,
                service: kBookingService,
                onChanged: (value) {
                  final normalized = DateTime(value.year, value.month, value.day);
                  onStartChanged(normalized);
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AppDatePicker(
                label: 'По',
                hint: 'Дата конца',
                value: end,
                firstDate: start,
                service: kBookingService,
                onChanged: (value) {
                  final normalized = DateTime(value.year, value.month, value.day);
                  onEndChanged(normalized);
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
  const _PresetChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = bookingServiceAccent(context.colors);

    return Material(
      color: accent.soft,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: accent.ctaBorder.withValues(alpha: 0.85)),
          ),
          child: Text(
            label,
            style: AppTextStyle.base(13, color: accent.icon, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}
