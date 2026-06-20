import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_bottom_sheet.dart';
import 'package:clover/core/shared/app_button.dart';
import 'package:clover/core/shared/app_date_picker.dart';
import 'package:clover/feature/booking/booking_list/data/models/booking_list_date_range.dart';
import 'package:flutter/material.dart';

abstract final class BookingListPeriodFilterSheet {
  static Future<BookingListDateRange?> show(
    BuildContext context, {
    required BookingListDateRange initial,
  }) {
    return AppBottomSheet.show<BookingListDateRange>(
      context: context,
      title: 'Фильтр по дате',
      upperCaseTitle: false,
      showCloseButton: true,
      content: _BookingListPeriodFilterContent(initial: initial),
    );
  }
}

class _BookingListPeriodFilterContent extends StatefulWidget {
  const _BookingListPeriodFilterContent({required this.initial});

  final BookingListDateRange initial;

  @override
  State<_BookingListPeriodFilterContent> createState() => _BookingListPeriodFilterContentState();
}

class _BookingListPeriodFilterContentState extends State<_BookingListPeriodFilterContent> {
  late DateTime _start;
  late DateTime _end;

  @override
  void initState() {
    super.initState();
    _start = widget.initial.start;
    _end = widget.initial.end;
  }

  void _applyToday() {
    final now = DateTime.now();
    final day = DateTime(now.year, now.month, now.day);
    setState(() {
      _start = day;
      _end = day;
    });
  }

  void _applyWeek() {
    final now = DateTime.now();
    final end = DateTime(now.year, now.month, now.day);
    setState(() {
      _end = end;
      _start = end.subtract(const Duration(days: 6));
    });
  }

  void _onStartChanged(DateTime value) {
    setState(() {
      _start = DateTime(value.year, value.month, value.day);
      if (_end.isBefore(_start)) _end = _start;
    });
  }

  void _onEndChanged(DateTime value) {
    setState(() {
      _end = DateTime(value.year, value.month, value.day);
      if (_start.isAfter(_end)) _start = _end;
    });
  }

  void _apply() {
    Navigator.pop(context, BookingListDateRange(start: _start, end: _end));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Период',
          style: AppTextStyle.base(14, color: AppColors.subTextColor, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _PresetChip(label: 'Сегодня', onTap: _applyToday),
            _PresetChip(label: 'Неделя', onTap: _applyWeek),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: AppDatePicker(
                label: 'С',
                hint: 'Дата начала',
                value: _start,
                lastDate: _end,
                onChanged: _onStartChanged,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AppDatePicker(
                label: 'По',
                hint: 'Дата конца',
                value: _end,
                firstDate: _start,
                onChanged: _onEndChanged,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        AppButton(text: 'Применить', isExpanded: true, onTap: _apply),
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
    return Material(
      color: AppColors.surfaceSoftBlue,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderCardBlue.withValues(alpha: 0.85)),
          ),
          child: Text(
            label,
            style: AppTextStyle.base(13, color: AppColors.functionalSoftBlueIcon, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}
