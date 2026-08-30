import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_bottom_sheet.dart';
import 'package:clover/core/shared/app_button.dart';
import 'package:clover/core/shared/app_date_picker.dart';
import 'package:clover/feature/_booking_/booking_list/data/models/booking_list_date_range.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

class _PeriodPreset {
  const _PeriodPreset({required this.label, required this.range});

  final String label;
  final BookingListDateRange range;
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

  static final _presets = [
    _PeriodPreset(label: 'Сегодня', range: BookingListDateRange.today()),
    _PeriodPreset(label: 'Завтра', range: BookingListDateRange.tomorrow()),
    _PeriodPreset(label: 'Эта неделя', range: BookingListDateRange.thisWeek()),
    _PeriodPreset(label: 'След. неделя', range: BookingListDateRange.nextWeek()),
    _PeriodPreset(label: 'Этот месяц', range: BookingListDateRange.thisMonth()),
    _PeriodPreset(label: 'След. месяц', range: BookingListDateRange.nextMonth()),
    _PeriodPreset(label: 'Все записи', range: BookingListDateRange.hostInbox()),
  ];

  @override
  void initState() {
    super.initState();
    _start = widget.initial.start;
    _end = widget.initial.end;
  }

  BookingListDateRange get _current => BookingListDateRange(start: _start, end: _end);

  void _applyPreset(BookingListDateRange range) {
    HapticFeedback.selectionClick();
    setState(() {
      _start = range.start;
      _end = range.end;
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
    final current = _current;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Быстрый выбор',
          style: AppTextStyle.base(14, color: context.colors.subTextColor, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final preset in _presets)
              _PresetChip(
                label: preset.label,
                selected: current.sameDayRange(preset.range),
                onTap: () => _applyPreset(preset.range),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Или свой период',
          style: AppTextStyle.base(14, color: context.colors.subTextColor, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
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
  const _PresetChip({
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final bg = selected ? context.colors.primary : context.colors.surfaceSoftBlue;
    final fg = selected ? context.colors.white : context.colors.functionalSoftBlueIcon;
    final border = selected
        ? context.colors.primary
        : context.colors.borderCardBlue.withValues(alpha: 0.85);

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border),
          ),
          child: Text(
            label,
            style: AppTextStyle.base(13, color: fg, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}
