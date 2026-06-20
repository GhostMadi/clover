import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_button.dart';
import 'package:clover/core/shared/app_date_picker.dart';
import 'package:clover/core/shared/app_field.dart';
import 'package:clover/core/shared/app_multi_selector.dart';
import 'package:clover/core/shared/app_outlined_button.dart';
import 'package:clover/core/shared/app_single_selctor.dart';
import 'package:clover/feature/booking/booking_create/data/models/booking_service_executor.dart';
import 'package:clover/feature/booking/booking_settings/data/models/booking_executor_absence.dart';
import 'package:clover/feature/booking/booking_settings/data/models/booking_schedule_settings.dart';
import 'package:clover/feature/booking/booking_settings/data/models/booking_weekday.dart';
import 'package:clover/feature/booking/shared/presentation/widget/booking_screen_shell.dart';
import 'package:flutter/material.dart';

class BookingScheduleSettingsForm extends StatelessWidget {
  const BookingScheduleSettingsForm({
    super.key,
    required this.settings,
    required this.executors,
    required this.onChanged,
    this.enabled = true,
  });

  final BookingScheduleSettings settings;
  final List<BookingServiceExecutor> executors;
  final ValueChanged<BookingScheduleSettings> onChanged;
  final bool enabled;

  static const _horizonModeOptions = [
    AppSingleSelectOption(value: BookingHorizonKind.daysAhead, label: 'На период'),
    AppSingleSelectOption(value: BookingHorizonKind.untilDate, label: 'До даты'),
  ];

  static const _horizonOptions = [
    AppSingleSelectOption(value: 7, label: '1 неделя'),
    AppSingleSelectOption(value: 14, label: '2 недели'),
    AppSingleSelectOption(value: 21, label: '3 недели'),
    AppSingleSelectOption(value: 30, label: '1 месяц'),
    AppSingleSelectOption(value: 60, label: '2 месяца'),
    AppSingleSelectOption(value: 90, label: '3 месяца'),
  ];

  static final _weekdayOptions = [
    for (final day in BookingWeekday.values)
      AppMultiSelectOption(value: day.isoWeekday, label: day.fullLabel),
  ];

  static final _hourOptions = [
    for (var h = 6; h <= 23; h++) AppSingleSelectOption(value: h, label: '${h.toString().padLeft(2, '0')}:00'),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 8, 16, BookingScreenShell.scrollBottomGap(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionCard(
            title: 'Выходные дни',
            subtitle: 'Клиент не сможет выбрать эти дни недели',
            child: IgnorePointer(
              ignoring: !enabled,
              child: Opacity(
                opacity: enabled ? 1 : 0.55,
                child: AppMultiSelect<int>(
                  label: 'Дни отдыха',
                  hint: 'Выберите дни',
                  sheetTitle: 'Выходные дни',
                  emptySelectionHint: 'Нет выходных',
                  options: _weekdayOptions,
                  values: settings.restWeekdays,
                  onChanged: (value) => onChanged(settings.copyWith(restWeekdays: value)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Горизонт записи',
            subtitle: 'На сколько вперёд клиент может записаться',
            child: IgnorePointer(
              ignoring: !enabled,
              child: Opacity(
                opacity: enabled ? 1 : 0.55,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppSingleSelect<BookingHorizonKind>(
                      label: 'Способ',
                      hint: 'Выберите способ',
                      sheetTitle: 'Горизонт записи',
                      options: _horizonModeOptions,
                      value: settings.horizonKind,
                      onChanged: (value) {
                        final today = DateTime.now();
                        final base = DateTime(today.year, today.month, today.day);
                        onChanged(
                          settings.copyWith(
                            horizonKind: value,
                            maxBookingUntilDate: value == BookingHorizonKind.untilDate
                                ? (settings.maxBookingUntilDate ?? base.add(Duration(days: settings.maxBookingDaysAhead)))
                                : settings.maxBookingUntilDate,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    if (settings.horizonKind == BookingHorizonKind.daysAhead)
                      AppSingleSelect<int>(
                        label: 'Максимальный срок',
                        hint: 'Выберите период',
                        sheetTitle: 'Запись вперёд',
                        options: _horizonOptions,
                        value: settings.maxBookingDaysAhead,
                        onChanged: (value) => onChanged(settings.copyWith(maxBookingDaysAhead: value)),
                      )
                    else
                      AppDatePicker(
                        label: 'Запись до',
                        hint: 'Выберите дату',
                        value: settings.maxBookingUntilDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        onChanged: (value) => onChanged(
                          settings.copyWith(maxBookingUntilDate: DateTime(value.year, value.month, value.day)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Рабочие часы',
            subtitle: 'Общее время приёма в течение дня',
            child: IgnorePointer(
              ignoring: !enabled,
              child: Opacity(
                opacity: enabled ? 1 : 0.55,
                child: Row(
                  children: [
                    Expanded(
                      child: AppSingleSelect<int>(
                        label: 'С',
                        hint: '09:00',
                        sheetTitle: 'Начало работы',
                        options: _hourOptions,
                        value: settings.workStartHour,
                        onChanged: (value) => onChanged(settings.copyWith(workStartHour: value)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppSingleSelect<int>(
                        label: 'До',
                        hint: '20:00',
                        sheetTitle: 'Конец работы',
                        options: _hourOptions,
                        value: settings.workEndHour,
                        onChanged: (value) => onChanged(settings.copyWith(workEndHour: value)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Буфер между услугами',
            subtitle: 'Задаётся отдельно для каждой услуги при создании. При редактировании изменить нельзя.',
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceSoft,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border.withValues(alpha: 0.45)),
              ),
              child: Text(
                'Например, 10 минут после стрижки — время на уборку. Откройте услугу и создайте новую, если нужен другой буфер.',
                style: AppTextStyle.base(13, color: AppColors.subTextColor, height: 1.35),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _ExecutorAbsenceSection(
            absences: settings.executorAbsences,
            executors: executors,
            enabled: enabled,
            onChanged: (absences) => onChanged(settings.copyWith(executorAbsences: absences)),
          ),
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
    final executorOptions = [
      for (final executor in widget.executors)
        AppSingleSelectOption(value: executor.id, label: executor.displayLabel),
    ];

    return _SectionCard(
      title: 'Недоступность исполнителей',
      subtitle: 'Отпуск, больничный — клиент не сможет записаться на эти дни',
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
          if (_adding) ...[
            IgnorePointer(
              ignoring: !widget.enabled,
              child: Opacity(
                opacity: widget.enabled ? 1 : 0.55,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppSingleSelect<String>(
                      label: 'Исполнитель',
                      hint: 'Выберите мастера',
                      sheetTitle: 'Исполнитель',
                      options: executorOptions,
                      value: _draftExecutorId,
                      onChanged: (value) => setState(() => _draftExecutorId = value),
                    ),
                    const SizedBox(height: 12),
                    AppDatePicker(
                      label: 'С',
                      hint: 'Дата начала',
                      value: _draftStart,
                      firstDate: DateTime.now().subtract(const Duration(days: 1)),
                      onChanged: (value) => setState(() => _draftStart = value),
                    ),
                    const SizedBox(height: 12),
                    AppDatePicker(
                      label: 'По',
                      hint: 'Дата окончания',
                      value: _draftEnd,
                      firstDate: _draftStart ?? DateTime.now().subtract(const Duration(days: 1)),
                      onChanged: (value) => setState(() => _draftEnd = value),
                    ),
                    const SizedBox(height: 12),
                    AppField(
                      controller: _noteController,
                      labelText: 'Комментарий',
                      hintText: 'Отпуск, командировка…',
                      textInputAction: TextInputAction.done,
                      isEnabled: widget.enabled,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: AppOutlinedButton(
                            text: 'Отмена',
                            height: 48,
                            isExpanded: true,
                            onTap: widget.enabled ? () => setState(_resetDraft) : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: AppButton(
                            text: 'Добавить',
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
            ),
          ] else
            AppOutlinedButton(
              text: 'Добавить период',
              height: 48,
              isExpanded: true,
              onTap: widget.enabled ? () => setState(() => _adding = true) : null,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_rounded, size: 18, color: widget.enabled ? AppColors.textColor : AppColors.subTextColor),
                  const SizedBox(width: 6),
                  Text(
                    'Добавить период',
                    style: AppTextStyle.base(
                      16,
                      fontWeight: FontWeight.w700,
                      color: widget.enabled ? AppColors.textColor : AppColors.subTextColor,
                    ),
                  ),
                ],
              ),
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
    final name = executor?.displayName ?? 'Исполнитель';
    final range = '${AppDatePicker.formatDisplay(absence.startDay)} — ${AppDatePicker.formatDisplay(absence.endDay)}';
    final note = absence.note?.trim();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.55)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(name, style: AppTextStyle.base(14, color: AppColors.textColor, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(range, style: AppTextStyle.base(13, color: AppColors.subTextColor, fontWeight: FontWeight.w600)),
                if (note != null && note.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(note, style: AppTextStyle.base(12, color: AppColors.subTextColor)),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: enabled ? onRemove : null,
            icon: const Icon(Icons.close_rounded, size: 20),
            color: AppColors.subTextColor,
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: AppTextStyle.base(15, color: AppColors.textColor, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(subtitle, style: AppTextStyle.base(12, color: AppColors.subTextColor, height: 1.3)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
