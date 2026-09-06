import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_bottom_sheet.dart';
import 'package:clover/core/shared/app_button.dart';
import 'package:clover/core/shared/app_picker_common.dart';
import 'package:flutter/material.dart';

/// Поле выбора даты (месяц + день) с кастомной шторкой-барабанами.
class AppDatePicker extends StatelessWidget {
  const AppDatePicker({
    super.key,
    this.label,
    required this.hint,
    required this.value,
    required this.onChanged,
    this.firstDate,
    this.lastDate,
    this.enabled = true,
    this.service,
  });

  final String? label;
  final String hint;
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final bool enabled;
  final AppServiceKind? service;

  static const _months = <String>[
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

  static String formatDisplay(DateTime date) {
    return '${date.day} ${_months[date.month - 1].toLowerCase()}';
  }

  Future<void> _openSheet(BuildContext context) async {
    final picked = await AppBottomSheet.show<DateTime>(
      context: context,
      title: label ?? 'Дата',
      upperCaseTitle: false,
      showCloseButton: true,
      service: service,
      contentHeight: MediaQuery.sizeOf(context).height * 0.42,
      contentBottomSpacing: 0,
      content: _AppDatePickerSheet(
        initial: value ?? DateTime.now(),
        firstDate: firstDate,
        lastDate: lastDate,
        service: service,
      ),
    );

    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    return AppPickerFieldShell(
      label: label,
      hint: hint,
      displayText: value == null ? null : formatDisplay(value!),
      prefixIcon: AppIcons.calendarToday.icon,
      enabled: enabled,
      service: service,
      onTap: enabled ? () => _openSheet(context) : null,
    );
  }
}

class _AppDatePickerSheet extends StatefulWidget {
  const _AppDatePickerSheet({
    required this.initial,
    this.firstDate,
    this.lastDate,
    this.service,
  });

  final DateTime initial;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final AppServiceKind? service;

  @override
  State<_AppDatePickerSheet> createState() => _AppDatePickerSheetState();
}

class _AppDatePickerSheetState extends State<_AppDatePickerSheet> {
  late int _month;
  late int _day;

  DateTime get _now => DateTime.now();

  int get _year {
    final now = _now;
    var year = now.year;
    final candidate = DateTime(year, _month, _day);
    final today = DateTime(now.year, now.month, now.day);
    if (candidate.isBefore(today)) year += 1;
    return year;
  }

  int get _daysInMonth => DateTime(_year, _month + 1, 0).day;

  List<int> get _dayItems => List.generate(_daysInMonth, (i) => i + 1);

  @override
  void initState() {
    super.initState();
    _month = widget.initial.month;
    _day = widget.initial.day.clamp(1, DateTime(widget.initial.year, widget.initial.month + 1, 0).day);
  }

  DateTime get _selected => DateTime(_year, _month, _day);

  void _onMonthChanged(int index) {
    setState(() {
      _month = index + 1;
      if (_day > _daysInMonth) _day = _daysInMonth;
    });
  }

  void _onDayChanged(int index) {
    setState(() => _day = _dayItems[index]);
  }

  void _confirm() {
    var result = _selected;
    final min = widget.firstDate;
    final max = widget.lastDate;
    if (min != null && result.isBefore(DateTime(min.year, min.month, min.day))) {
      result = DateTime(min.year, min.month, min.day);
    }
    if (max != null && result.isAfter(DateTime(max.year, max.month, max.day))) {
      result = DateTime(max.year, max.month, max.day);
    }
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            AppDatePicker.formatDisplay(_selected),
            textAlign: TextAlign.center,
            style: AppTextStyle.base(20, fontWeight: FontWeight.w700, color: colors.textColor),
          ),
        ),
        Text(
          '$_year',
          textAlign: TextAlign.center,
          style: AppTextStyle.base(14, color: colors.subTextColor),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: AppPickerWheel(
                  items: AppDatePicker._months,
                  selectedIndex: _month - 1,
                  onSelectedIndexChanged: _onMonthChanged,
                  service: widget.service,
                ),
              ),
              Expanded(
                child: AppPickerWheel(
                  items: _dayItems.map((d) => d.toString()).toList(),
                  selectedIndex: (_day - 1).clamp(0, _dayItems.length - 1),
                  onSelectedIndexChanged: _onDayChanged,
                  service: widget.service,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.only(top: 8, bottom: bottom),
          child: AppButton(
            text: 'Готово',
            isExpanded: true,
            service: widget.service,
            onTap: _confirm,
          ),
        ),
      ],
    );
  }
}
