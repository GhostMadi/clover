import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/extension/context.dart';
import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_date_picker.dart';
import 'package:clover/core/shared/app_multi_selector.dart';
import 'package:clover/core/shared/app_outlined_button.dart';
import 'package:clover/core/shared/app_single_selctor.dart';
import 'package:clover/feature/_booking_/booking_create/data/models/booking_service_executor.dart';
import 'package:clover/feature/_booking_/booking_settings/data/models/booking_executor_absence.dart';
import 'package:clover/feature/_booking_/booking_settings/data/models/booking_schedule_settings.dart';
import 'package:clover/feature/_booking_/booking_settings/data/models/booking_weekday.dart';
import 'package:clover/feature/_booking_/booking_settings/presentation/widget/booking_schedule_ops_sections.dart';
import 'package:clover/feature/_booking_/shared/data/models/booking_horizon_kind.dart';
import 'package:clover/feature/_booking_/shared/presentation/widget/booking_screen_shell.dart';
import 'package:clover/feature/_booking_/shared/presentation/widget/booking_service_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Расписание точки: сверху выходные / горизонт / часы, остальное — в «Ещё».
class BookingScheduleSettingsForm extends StatefulWidget {
  const BookingScheduleSettingsForm({
    super.key,
    required this.pointId,
    required this.settings,
    required this.executors,
    required this.onChanged,
    this.enabled = true,
  });

  final String pointId;
  final BookingScheduleSettings settings;
  final List<BookingServiceExecutor> executors;
  final ValueChanged<BookingScheduleSettings> onChanged;
  final bool enabled;

  @override
  State<BookingScheduleSettingsForm> createState() => _BookingScheduleSettingsFormState();
}

class _BookingScheduleSettingsFormState extends State<BookingScheduleSettingsForm> {
  List<AppSingleSelectOption<BookingHorizonKind>> _horizonModeOptions(BuildContext context) {
    final l10n = context.l10n;
    return [
      AppSingleSelectOption(value: BookingHorizonKind.daysAhead, label: l10n.booking_horizon_days_ahead),
      AppSingleSelectOption(value: BookingHorizonKind.untilDate, label: l10n.booking_horizon_until_date),
    ];
  }

  List<AppSingleSelectOption<int>> _horizonOptions(BuildContext context) {
    final l10n = context.l10n;
    return [
      AppSingleSelectOption(value: 7, label: l10n.booking_week_1),
      AppSingleSelectOption(value: 14, label: l10n.booking_weeks_n(2)),
      AppSingleSelectOption(value: 21, label: l10n.booking_weeks_n(3)),
      AppSingleSelectOption(value: 30, label: l10n.booking_month_1),
      AppSingleSelectOption(value: 60, label: l10n.booking_months_n(2)),
      AppSingleSelectOption(value: 90, label: l10n.booking_months_n(3)),
    ];
  }

  List<AppMultiSelectOption<int>> _weekdayOptions(BuildContext context) => [
        for (final day in BookingWeekday.values)
          AppMultiSelectOption(value: day.isoWeekday, label: day.fullLabel(context.dateFormat)),
      ];

  static final _hourOptions = [
    for (var h = 6; h <= 23; h++) AppSingleSelectOption(value: h, label: '${h.toString().padLeft(2, '0')}:00'),
  ];

  late bool _moreOpen;

  BookingScheduleSettings get settings => widget.settings;

  @override
  void initState() {
    super.initState();
    final s = widget.settings;
    _moreOpen = s.executorAbsences.isNotEmpty ||
        s.clientCancelHoursBefore > 0 ||
        s.autoCloseHoursAfterVisit > 0;
  }

  Widget _gated({required Widget child}) {
    return IgnorePointer(
      ignoring: !widget.enabled,
      child: Opacity(opacity: widget.enabled ? 1 : 0.55, child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 8, 16, BookingScreenShell.scrollBottomGap(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Section(
            title: l10n.booking_rest_days,
            child: _gated(
              child: AppMultiSelect<int>(
                label: l10n.booking_days,
                hint: l10n.booking_select,
                sheetTitle: l10n.booking_rest_days,
                emptySelectionHint: l10n.common_no,
                options: _weekdayOptions(context),
                values: settings.restWeekdays,
                onChanged: (value) => widget.onChanged(settings.copyWith(restWeekdays: value)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _Section(
            title: l10n.booking_horizon,
            child: _gated(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppSingleSelect<BookingHorizonKind>(
                    label: l10n.booking_horizon_mode,
                    hint: l10n.booking_select,
                    sheetTitle: l10n.booking_horizon,
                    options: _horizonModeOptions(context),
                    value: settings.horizonKind,
                    onChanged: (value) {
                      final today = DateTime.now();
                      final base = DateTime(today.year, today.month, today.day);
                      widget.onChanged(
                        settings.copyWith(
                          horizonKind: value,
                          maxBookingUntilDate: value == BookingHorizonKind.untilDate
                              ? (settings.maxBookingUntilDate ??
                                  base.add(Duration(days: settings.maxBookingDaysAhead)))
                              : settings.maxBookingUntilDate,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  if (settings.horizonKind == BookingHorizonKind.daysAhead)
                    AppSingleSelect<int>(
                      label: l10n.booking_horizon_how_far,
                      hint: l10n.booking_horizon_period,
                      sheetTitle: l10n.booking_horizon_forward,
                      options: _horizonOptions(context),
                      value: settings.maxBookingDaysAhead,
                      onChanged: (value) =>
                          widget.onChanged(settings.copyWith(maxBookingDaysAhead: value)),
                    )
                  else
                    AppDatePicker(
                      label: l10n.booking_until_date,
                      hint: l10n.common_date,
                      value: settings.maxBookingUntilDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      service: kBookingService,
                      onChanged: (value) => widget.onChanged(
                        settings.copyWith(
                          maxBookingUntilDate: DateTime(value.year, value.month, value.day),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _Section(
            title: l10n.booking_hours_title,
            child: _gated(
              child: Row(
                children: [
                  Expanded(
                    child: AppSingleSelect<int>(
                      label: l10n.booking_from,
                      hint: '09:00',
                      sheetTitle: l10n.common_start_label,
                      options: _hourOptions,
                      value: settings.workStartHour,
                      onChanged: (value) => widget.onChanged(settings.copyWith(workStartHour: value)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppSingleSelect<int>(
                      label: l10n.booking_to,
                      hint: '20:00',
                      sheetTitle: l10n.common_end_label,
                      options: _hourOptions,
                      value: settings.workEndHour,
                      onChanged: (value) => widget.onChanged(settings.copyWith(workEndHour: value)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Material(
            color: colors.surfaceMuted.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _moreOpen = !_moreOpen);
              },
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.booking_more_settings,
                        style: AppTextStyle.base(
                          14,
                          color: colors.textColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Icon(
                      _moreOpen ? AppIcons.arrowUp.icon : AppIcons.arrowDown.icon,
                      size: 22,
                      color: colors.iconMuted,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_moreOpen) ...[
            const SizedBox(height: 12),
            _Section(
              title: l10n.booking_cancel_visits_title,
              child: _gated(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppSingleSelect<int>(
                      label: l10n.booking_client_cancel,
                      hint: l10n.booking_select,
                      sheetTitle: l10n.common_cancel,
                      options: [
                        AppSingleSelectOption(value: 0, label: l10n.booking_cancel_before_start),
                        AppSingleSelectOption(value: 1, label: l10n.booking_hours_before(1)),
                        AppSingleSelectOption(value: 2, label: l10n.booking_hours_before(2)),
                        AppSingleSelectOption(value: 3, label: l10n.booking_hours_before(3)),
                        AppSingleSelectOption(value: 6, label: l10n.booking_hours_before(6)),
                        AppSingleSelectOption(value: 12, label: l10n.booking_hours_before(12)),
                        AppSingleSelectOption(value: 24, label: l10n.booking_hours_before(24)),
                      ],
                      value: settings.clientCancelHoursBefore,
                      onChanged: (value) =>
                          widget.onChanged(settings.copyWith(clientCancelHoursBefore: value)),
                    ),
                    const SizedBox(height: 12),
                    AppSingleSelect<int>(
                      label: l10n.booking_auto_no_show,
                      hint: l10n.booking_select,
                      sheetTitle: l10n.booking_auto_status,
                      options: [
                        AppSingleSelectOption(value: 0, label: l10n.booking_off),
                        AppSingleSelectOption(value: 3, label: l10n.booking_after_hours(3)),
                        AppSingleSelectOption(value: 6, label: l10n.booking_after_hours(6)),
                        AppSingleSelectOption(value: 12, label: l10n.booking_after_hours(12)),
                        AppSingleSelectOption(value: 24, label: l10n.booking_after_hours(24)),
                      ],
                      value: settings.autoCloseHoursAfterVisit,
                      onChanged: (value) =>
                          widget.onChanged(settings.copyWith(autoCloseHoursAfterVisit: value)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _ExecutorAbsenceSection(
              absences: settings.executorAbsences,
              executors: widget.executors,
              enabled: widget.enabled,
              onChanged: (absences) =>
                  widget.onChanged(settings.copyWith(executorAbsences: absences)),
            ),
            const SizedBox(height: 12),
            BookingScheduleOpsSections(
              pointId: widget.pointId,
              executors: widget.executors,
              enabled: widget.enabled,
            ),
          ],
        ],
      ),
    );
  }
}

class _ExecutorAbsenceSection extends StatefulWidget {
  const _ExecutorAbsenceSection({
    required this.absences,
    required this.executors,
    required this.enabled,
    required this.onChanged,
  });

  final List<BookingExecutorAbsence> absences;
  final List<BookingServiceExecutor> executors;
  final bool enabled;
  final ValueChanged<List<BookingExecutorAbsence>> onChanged;

  @override
  State<_ExecutorAbsenceSection> createState() => _ExecutorAbsenceSectionState();
}

class _ExecutorAbsenceSectionState extends State<_ExecutorAbsenceSection> {
  bool _adding = false;
  String? _draftExecutorId;
  DateTime? _draftStart;
  DateTime? _draftEnd;
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  BookingServiceExecutor? _executorById(String? id) {
    if (id == null) return null;
    for (final executor in widget.executors) {
      if (executor.id == id) return executor;
    }
    return null;
  }

  void _resetDraft() {
    _draftExecutorId = null;
    _draftStart = null;
    _draftEnd = null;
    _noteController.clear();
    _adding = false;
  }

  void _addAbsence() {
    final executorId = _draftExecutorId;
    final start = _draftStart;
    final end = _draftEnd;
    if (executorId == null || start == null || end == null) return;
    if (end.isBefore(start)) return;

    final absence = BookingExecutorAbsence(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      executorId: executorId,
      startDay: DateTime(start.year, start.month, start.day),
      endDay: DateTime(end.year, end.month, end.day),
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
    );

    widget.onChanged([...widget.absences, absence]);
    setState(_resetDraft);
  }

  void _removeAbsence(String id) {
    widget.onChanged([
      for (final absence in widget.absences)
        if (absence.id != id) absence,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final executorOptions = [
      for (final executor in widget.executors)
        AppSingleSelectOption(value: executor.id, label: executor.displayLabel),
    ];

    return _Section(
      title: l10n.booking_absences_title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final absence in widget.absences) ...[
            _AbsenceTile(
              absence: absence,
              executor: _executorById(absence.executorId),
              enabled: widget.enabled,
              onRemove: () => _removeAbsence(absence.id),
            ),
            const SizedBox(height: 8),
          ],
          if (_adding)
            IgnorePointer(
              ignoring: !widget.enabled,
              child: Opacity(
                opacity: widget.enabled ? 1 : 0.55,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppSingleSelect<String>(
                      label: l10n.booking_master,
                      hint: l10n.booking_select,
                      sheetTitle: l10n.booking_master,
                      options: executorOptions,
                      value: _draftExecutorId,
                      onChanged: (value) => setState(() => _draftExecutorId = value),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: AppDatePicker(
                            label: l10n.booking_from,
                            hint: l10n.common_start_label,
                            value: _draftStart,
                            firstDate: DateTime.now().subtract(const Duration(days: 1)),
                            service: kBookingService,
                            onChanged: (value) => setState(() => _draftStart = value),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: AppDatePicker(
                            label: l10n.booking_to_inclusive,
                            hint: l10n.common_end_label,
                            value: _draftEnd,
                            firstDate: _draftStart ?? DateTime.now().subtract(const Duration(days: 1)),
                            service: kBookingService,
                            onChanged: (value) => setState(() => _draftEnd = value),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    BookingField(
                      controller: _noteController,
                      labelText: l10n.booking_comment,
                      hintText: l10n.booking_optional,
                      textInputAction: TextInputAction.done,
                      isEnabled: widget.enabled,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: AppOutlinedButton(
                            service: kBookingService,
                            text: context.l10n.common_cancel,
                            height: 48,
                            isExpanded: true,
                            onTap: widget.enabled ? () => setState(_resetDraft) : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: BookingPrimaryButton(
                            text: context.l10n.common_add,
                            height: 48,
                            isExpanded: true,
                            onTap: widget.enabled &&
                                    _draftExecutorId != null &&
                                    _draftStart != null &&
                                    _draftEnd != null
                                ? _addAbsence
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
          else
            AppOutlinedButton(
              service: kBookingService,
              text: context.l10n.common_add,
              height: 48,
              isExpanded: true,
              onTap: widget.enabled ? () => setState(() => _adding = true) : null,
            ),
        ],
      ),
    );
  }
}

class _AbsenceTile extends StatelessWidget {
  const _AbsenceTile({
    required this.absence,
    required this.executor,
    required this.enabled,
    required this.onRemove,
  });

  final BookingExecutorAbsence absence;
  final BookingServiceExecutor? executor;
  final bool enabled;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final name = executor?.displayName ?? context.l10n.booking_master;
    final range = '${AppDatePicker.formatDisplay(absence.startDay)} — ${AppDatePicker.formatDisplay(absence.endDay)}';
    final note = absence.note?.trim();

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
      decoration: BoxDecoration(
        color: colors.surfaceSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTextStyle.base(14, color: colors.textColor, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(range, style: AppTextStyle.base(13, color: colors.subTextColor, fontWeight: FontWeight.w600)),
                if (note != null && note.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(note, style: AppTextStyle.base(12, color: colors.subTextColor)),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: enabled ? onRemove : null,
            icon: Icon(AppIcons.closeRounded.icon, size: 20),
            color: colors.subTextColor,
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border.withValues(alpha: 0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: AppTextStyle.base(15, color: colors.textColor, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
