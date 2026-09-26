import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/extension/context.dart';
import 'package:clover/core/locale/app_date_format.dart';
import 'package:clover/core/locale/app_locale_cubit.dart';
import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_bottom_sheet.dart';
import 'package:clover/core/shared/app_button.dart';
import 'package:clover/core/shared/app_picker_common.dart';
import 'package:clover/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Период события: дата и время начала и окончания.
class AppDateTimeRange {
  const AppDateTimeRange({required this.start, required this.end});

  final DateTime start;
  final DateTime end;

  Duration get duration => end.difference(start);

  AppDateTimeRange copyWith({DateTime? start, DateTime? end}) {
    return AppDateTimeRange(start: start ?? this.start, end: end ?? this.end);
  }
}

/// Поле выбора периода ивента (начало и конец) — для расчёта `duration` на сервере.
class AppTimePicker extends StatelessWidget {
  const AppTimePicker({
    super.key,
    this.label,
    required this.hint,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.minuteStep = 1,
    this.maxDuration = const Duration(hours: 24),
  });

  final String? label;
  final String hint;
  final AppDateTimeRange? value;
  final ValueChanged<AppDateTimeRange> onChanged;
  final bool enabled;
  final int minuteStep;

  /// Ограничение как на бэке: `markers.duration <= 24 hours`.
  final Duration maxDuration;

  static String formatTime(DateTime dateTime) {
    final h = dateTime.hour.toString().padLeft(2, '0');
    final m = dateTime.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  static String formatShortDate(DateTime dateTime, {String locale = 'ru'}) {
    return AppDateFormat(locale).dayMonthLong(dateTime);
  }

  static String formatDateTime(DateTime dateTime, {String locale = 'ru'}) {
    return '${formatShortDate(dateTime, locale: locale)} · ${formatTime(dateTime)}';
  }

  /// «15 июня, суббота · 14:30»
  static String formatEventStart(DateTime dateTime, {String locale = 'ru'}) {
    final local = dateTime.toLocal();
    final dates = AppDateFormat(locale);
    return '${dates.dayMonthLong(local)}, ${dates.fullWeekday(local)} · ${formatTime(local)}';
  }

  static String formatCountdown(Duration remaining) {
    final totalSeconds = remaining.inSeconds.clamp(0, 99 * 3600 + 59 * 60 + 59);
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  static String formatDaysRemaining(int days, [AppLocalizations? l10n]) {
    final loc = l10n ?? lookupAppLocalizations(sl<AppLocaleCubit>().state.locale);
    return loc.common_days_plural(days);
  }

  static String formatDuration(Duration duration, [AppLocalizations? l10n]) {
    final loc = l10n ?? lookupAppLocalizations(sl<AppLocaleCubit>().state.locale);
    final totalMinutes = duration.inMinutes;
    if (totalMinutes <= 0) return loc.common_zero_minutes;

    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;

    if (hours == 0) return loc.common_minutes_unit(minutes);
    if (minutes == 0) return loc.common_hours_unit(hours);
    return loc.common_hours_minutes(hours, minutes);
  }

  static String formatRangeDisplay(AppDateTimeRange range, {String locale = 'ru'}) {
    final sameDay =
        range.start.year == range.end.year &&
        range.start.month == range.end.month &&
        range.start.day == range.end.day;

    if (sameDay) {
      return '${formatShortDate(range.start, locale: locale)} · ${formatTime(range.start)}–${formatTime(range.end)}';
    }

    return '${formatDateTime(range.start, locale: locale)} — ${formatDateTime(range.end, locale: locale)}';
  }

  Future<void> _openSheet(BuildContext context) async {
    final now = DateTime.now();
    final defaultStart = DateTime(now.year, now.month, now.day, now.hour, now.minute);
    final initial =
        value ?? AppDateTimeRange(start: defaultStart, end: defaultStart.add(const Duration(hours: 2)));

    final picked = await AppBottomSheet.show<AppDateTimeRange>(
      context: context,
      title: label ?? context.l10n.common_event_period,
      upperCaseTitle: false,
      showCloseButton: true,
      contentHeight: MediaQuery.sizeOf(context).height * 0.58,
      contentBottomSpacing: 0,
      content: _AppDateTimeRangeSheet(initial: initial, minuteStep: minuteStep, maxDuration: maxDuration),
    );

    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    return AppPickerFieldShell(
      label: label,
      hint: hint,
      displayText: value == null ? null : formatRangeDisplay(value!, locale: context.l10n.localeName),
      prefixIcon: AppIcons.schedule.icon,
      enabled: enabled,
      onTap: enabled ? () => _openSheet(context) : null,
    );
  }
}

enum _RangeSide { start, end }

class _AppDateTimeRangeSheet extends StatefulWidget {
  const _AppDateTimeRangeSheet({required this.initial, required this.minuteStep, required this.maxDuration});

  final AppDateTimeRange initial;
  final int minuteStep;
  final Duration maxDuration;

  @override
  State<_AppDateTimeRangeSheet> createState() => _AppDateTimeRangeSheetState();
}

class _AppDateTimeRangeSheetState extends State<_AppDateTimeRangeSheet> {
  late DateTime _start;
  late DateTime _end;
  _RangeSide _side = _RangeSide.start;
  String? _error;

  DateTime get _active => _side == _RangeSide.start ? _start : _end;

  List<int> get _hours => List.generate(24, (i) => i);

  List<int> get _minutes {
    final step = widget.minuteStep.clamp(1, 30);
    final items = <int>[];
    for (var m = 0; m < 60; m += step) {
      items.add(m);
    }
    return items;
  }

  @override
  void initState() {
    super.initState();
    _start = widget.initial.start;
    _end = widget.initial.end;
    _normalizeRange();
  }

  int _yearForMonthDay(int month, int day) {
    final now = DateTime.now();
    var year = now.year;
    final candidate = DateTime(year, month, day);
    final today = DateTime(now.year, now.month, now.day);
    if (candidate.isBefore(today)) year += 1;
    return year;
  }

  int _daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;

  void _normalizeRange() {
    if (!_end.isAfter(_start)) {
      _end = _start.add(const Duration(hours: 1));
    }

    final maxEnd = _start.add(widget.maxDuration);
    if (_end.isAfter(maxEnd)) {
      _end = maxEnd;
    }
  }

  void _setActive(DateTime next) {
    setState(() {
      if (_side == _RangeSide.start) {
        _start = next;
      } else {
        _end = next;
      }
      _normalizeRange();
      _error = null;
    });
  }

  void _onMonthChanged(int index) {
    final month = index + 1;
    final year = _yearForMonthDay(month, _active.day);
    final day = _active.day.clamp(1, _daysInMonth(year, month));
    _setActive(DateTime(year, month, day, _active.hour, _active.minute));
  }

  void _onDayChanged(int index) {
    final day = index + 1;
    _setActive(DateTime(_active.year, _active.month, day, _active.hour, _active.minute));
  }

  void _onHourChanged(int hour) {
    _setActive(DateTime(_active.year, _active.month, _active.day, hour, _active.minute));
  }

  void _onMinuteChanged(int minuteIndex) {
    final minute = _minutes[minuteIndex.clamp(0, _minutes.length - 1)];
    _setActive(DateTime(_active.year, _active.month, _active.day, _active.hour, minute));
  }

  int _nearestMinuteIndex(int minute) {
    var best = 0;
    var bestDiff = 999;
    for (var i = 0; i < _minutes.length; i++) {
      final diff = (minute - _minutes[i]).abs();
      if (diff < bestDiff) {
        bestDiff = diff;
        best = i;
      }
    }
    return best;
  }

  void _confirm() {
    _normalizeRange();
    if (!_end.isAfter(_start)) {
      setState(() => _error = context.l10n.common_end_after_start);
      return;
    }
    if (_end.difference(_start) > widget.maxDuration) {
      setState(
        () => _error = context.l10n.common_max_duration(
          AppTimePicker.formatDuration(widget.maxDuration),
        ),
      );
      return;
    }
    Navigator.of(context).pop(AppDateTimeRange(start: _start, end: _end));
  }

  Widget _sideChip({required _RangeSide side, required String label, required AppPalette colors}) {
    final selected = _side == side;
    return Expanded(
      child: Material(
        color: selected ? colors.primary.withValues(alpha: 0.12) : colors.fieldBackground,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() {
            _side = side;
            _error = null;
          }),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? colors.primary.withValues(alpha: 0.45) : colors.fieldBorder,
              ),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: AppTextStyle.base(
                14,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? colors.textColor : colors.subTextColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dates = context.dateFormat;
    final locale = context.l10n.localeName;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final active = _active;
    final dayItems = List.generate(_daysInMonth(active.year, active.month), (i) => i + 1);
    final duration = _end.difference(_start);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _sideChip(side: _RangeSide.start, label: context.l10n.common_start_label, colors: colors),
            const SizedBox(width: 8),
            _sideChip(side: _RangeSide.end, label: context.l10n.common_end_label, colors: colors),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          AppTimePicker.formatDateTime(active, locale: locale),
          textAlign: TextAlign.center,
          style: AppTextStyle.base(20, fontWeight: FontWeight.w700, color: colors.textColor),
        ),
        Text(
          '${active.year}',
          textAlign: TextAlign.center,
          style: AppTextStyle.base(14, color: colors.subTextColor),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Column(
            children: [
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    Expanded(
                      child: AppPickerWheel(
                        items: dates.monthNames(),
                        selectedIndex: active.month - 1,
                        onSelectedIndexChanged: _onMonthChanged,
                      ),
                    ),
                    Expanded(
                      child: AppPickerWheel(
                        items: dayItems.map((d) => d.toString()).toList(),
                        selectedIndex: (active.day - 1).clamp(0, dayItems.length - 1),
                        onSelectedIndexChanged: _onDayChanged,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 100,
                      child: AppPickerWheel(
                        items: _hours.map((h) => h.toString().padLeft(2, '0')).toList(),
                        selectedIndex: active.hour,
                        onSelectedIndexChanged: _onHourChanged,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        ':',
                        style: AppTextStyle.base(28, fontWeight: FontWeight.w700, color: colors.primary),
                      ),
                    ),
                    SizedBox(
                      width: 100,
                      child: AppPickerWheel(
                        items: _minutes.map((m) => m.toString().padLeft(2, '0')).toList(),
                        selectedIndex: _nearestMinuteIndex(active.minute),
                        onSelectedIndexChanged: _onMinuteChanged,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Text(
          context.l10n.common_duration(AppTimePicker.formatDuration(duration)),
          textAlign: TextAlign.center,
          style: AppTextStyle.base(14, color: colors.subTextColor, fontWeight: FontWeight.w600),
        ),
        if (_error != null) ...[
          const SizedBox(height: 6),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: AppTextStyle.base(13, color: colors.error),
          ),
        ],
        Padding(
          padding: EdgeInsets.only(top: 8, bottom: bottom),
          child: AppButton(text: context.l10n.common_done, isExpanded: true, onTap: _confirm),
        ),
      ],
    );
  }
}
