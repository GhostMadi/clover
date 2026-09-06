import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_bottom_sheet.dart';
import 'package:clover/core/shared/app_date_picker.dart';
import 'package:clover/core/shared/app_field.dart';
import 'package:clover/core/shared/app_outlined_button.dart';
import 'package:clover/core/shared/app_single_selctor.dart';
import 'package:clover/core/shared/app_snack_bar.dart';
import 'package:clover/feature/_booking_/booking_create/data/models/booking_service_executor.dart';
import 'package:clover/feature/_booking_/booking_settings/data/models/booking_weekday.dart';
import 'package:clover/feature/_booking_/booking_settings/presentation/cubit/booking_schedule_ops_cubit.dart';
import 'package:clover/feature/_booking_/shared/data/booking_error.dart';
import 'package:clover/feature/_booking_/shared/presentation/widget/booking_service_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Blocked slots + per-staff weekday hours (PostgREST, host RLS).
class BookingScheduleOpsSections extends StatefulWidget {
  const BookingScheduleOpsSections({
    super.key,
    required this.executors,
    this.enabled = true,
  });

  final List<BookingServiceExecutor> executors;
  final bool enabled;

  @override
  State<BookingScheduleOpsSections> createState() => _BookingScheduleOpsSectionsState();
}

class _BookingScheduleOpsSectionsState extends State<BookingScheduleOpsSections> {
  late final BookingScheduleOpsCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = sl<BookingScheduleOpsCubit>()..bind(widget.executors);
  }

  @override
  void didUpdateWidget(covariant BookingScheduleOpsSections oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.executors.isEmpty) return;
    final staffId = _cubit.state.scheduleStaffId;
    if (staffId == null || !widget.executors.any((e) => e.id == staffId)) {
      _cubit.selectStaff(widget.executors.first.id);
    }
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  Future<void> _addBlocked() async {
    if (!widget.enabled || widget.executors.isEmpty) return;
    var staffId = widget.executors.first.id;
    var day = DateTime.now();
    day = DateTime(day.year, day.month, day.day);
    var startH = 13;
    var endH = 14;
    final reasonCtrl = TextEditingController();

    final confirmed = await AppBottomSheet.show<bool>(
      context: context,
      title: 'Блок времени',
      service: kBookingService,
      contentHeight: 420,
      content: StatefulBuilder(
        builder: (ctx, setLocal) {
          return ListView(
            children: [
              AppSingleSelect<String>(
                label: 'Исполнитель',
                hint: 'Выберите',
                sheetTitle: 'Исполнитель',
                options: [
                  for (final e in widget.executors)
                    AppSingleSelectOption(value: e.id, label: e.displayName),
                ],
                value: staffId,
                onChanged: (v) => setLocal(() => staffId = v),
              ),
              const SizedBox(height: 10),
              AppDatePicker(
                label: 'День',
                hint: 'Дата',
                value: day,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 90)),
                service: kBookingService,
                onChanged: (d) => setLocal(() => day = DateTime(d.year, d.month, d.day)),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: AppSingleSelect<int>(
                      label: 'С',
                      hint: 'Час',
                      sheetTitle: 'Начало',
                      options: [
                        for (var h = 6; h <= 22; h++)
                          AppSingleSelectOption(value: h, label: '${h.toString().padLeft(2, '0')}:00'),
                      ],
                      value: startH,
                      onChanged: (v) => setLocal(() => startH = v),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AppSingleSelect<int>(
                      label: 'До',
                      hint: 'Час',
                      sheetTitle: 'Конец',
                      options: [
                        for (var h = 7; h <= 23; h++)
                          AppSingleSelectOption(value: h, label: '${h.toString().padLeft(2, '0')}:00'),
                      ],
                      value: endH,
                      onChanged: (v) => setLocal(() => endH = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              AppField(
                controller: reasonCtrl,
                labelText: 'Причина (необяз.)',
                hintText: 'Обед, совещание…',
                service: kBookingService,
              ),
            ],
          );
        },
      ),
      actions: [
        BookingPrimaryButton(
          text: 'Добавить',
          isExpanded: true,
          height: 48,
          onTap: () => Navigator.of(context).pop(true),
        ),
      ],
    );

    final reason = reasonCtrl.text;
    Future<void>.delayed(const Duration(milliseconds: 300), reasonCtrl.dispose);
    if (confirmed != true || !mounted) return;
    if (endH <= startH) {
      AppSnackBar.show(context, message: 'Конец должен быть позже начала', kind: AppSnackBarKind.error);
      return;
    }

    try {
      await _cubit.addBlocked(
        staffId: staffId,
        startsAt: DateTime(day.year, day.month, day.day, startH),
        endsAt: DateTime(day.year, day.month, day.day, endH),
        reason: reason,
      );
      if (!mounted) return;
      AppSnackBar.show(context, message: 'Время заблокировано', kind: AppSnackBarKind.success);
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.show(context, message: BookingException.from(e).userMessage, kind: AppSnackBarKind.error);
    }
  }

  Future<void> _toggleDay(BookingWeekday weekday, BookingScheduleOpsState state) async {
    if (!widget.enabled || state.scheduleStaffId == null) return;
    final existing = state.days.where((d) => d.weekday == weekday.isoWeekday).firstOrNull;
    final isWorking = !(existing?.isWorking ?? true);
    try {
      await _cubit.toggleWeekday(
        weekday: weekday.isoWeekday,
        isWorking: isWorking,
        workStartHour: isWorking ? (existing?.workStartHour ?? 9) : null,
        workEndHour: isWorking ? (existing?.workEndHour ?? 20) : null,
      );
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.show(context, message: BookingException.from(e).userMessage, kind: AppSnackBarKind.error);
    }
  }

  Future<void> _deleteBlocked(String id) async {
    try {
      await _cubit.deleteBlocked(id);
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.show(
        context,
        message: BookingException.from(e).userMessage,
        kind: AppSnackBarKind.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    String fmt(DateTime d) {
      final dd = d.day.toString().padLeft(2, '0');
      final mm = d.month.toString().padLeft(2, '0');
      final hh = d.hour.toString().padLeft(2, '0');
      final mi = d.minute.toString().padLeft(2, '0');
      return '$dd.$mm $hh:$mi';
    }
    final nameById = {for (final e in widget.executors) e.id: e.displayName};

    return BlocBuilder<BookingScheduleOpsCubit, BookingScheduleOpsState>(
      bloc: _cubit,
      builder: (context, state) {
        final colors = context.colors;
        final accent = bookingServiceAccent(colors);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.border.withValues(alpha: 0.55)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Блоки времени',
                    style: AppTextStyle.base(15, color: colors.textColor, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Обед или занятость без фейковой записи — слот не предложится клиенту.',
                    style: AppTextStyle.base(12, color: colors.subTextColor, height: 1.3),
                  ),
                  const SizedBox(height: 12),
                  if (state.loadingBlocked)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                  else if (state.blocked.isEmpty)
                    Text(
                      'Пока нет блоков на ближайшие 60 дней',
                      style: AppTextStyle.base(13, color: colors.subTextColor),
                    )
                  else
                    for (final b in state.blocked)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${nameById[b.staffId] ?? 'Мастер'} · ${fmt(b.startsAt)}–${fmt(b.endsAt)}'
                                '${b.reason != null && b.reason!.isNotEmpty ? ' · ${b.reason}' : ''}',
                                style: AppTextStyle.base(13, color: colors.textColor),
                              ),
                            ),
                            IconButton(
                              onPressed: widget.enabled ? () => _deleteBlocked(b.id) : null,
                              icon: Icon(AppIcons.closeRounded.icon, size: 18),
                              color: colors.subTextColor,
                            ),
                          ],
                        ),
                      ),
                  const SizedBox(height: 8),
                  AppOutlinedButton(
                    text: 'Заблокировать время',
                    isExpanded: true,
                    service: kBookingService,
                    onTap: widget.enabled && widget.executors.isNotEmpty ? _addBlocked : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.border.withValues(alpha: 0.55)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'График мастера',
                    style: AppTextStyle.base(15, color: colors.textColor, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Переопределение рабочих дней. Пусто = общие часы расписания.',
                    style: AppTextStyle.base(12, color: colors.subTextColor, height: 1.3),
                  ),
                  const SizedBox(height: 12),
                  if (widget.executors.isEmpty)
                    Text(
                      'Сначала добавьте исполнителей в услугах',
                      style: AppTextStyle.base(13, color: colors.subTextColor),
                    )
                  else ...[
                    AppSingleSelect<String>(
                      label: 'Исполнитель',
                      hint: 'Выберите',
                      sheetTitle: 'Исполнитель',
                      options: [
                        for (final e in widget.executors)
                          AppSingleSelectOption(value: e.id, label: e.displayName),
                      ],
                      value: state.scheduleStaffId,
                      onChanged: _cubit.selectStaff,
                    ),
                    const SizedBox(height: 12),
                    if (state.loadingSchedule)
                      const Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: BookingWeekday.values.map((day) {
                          final selected = state.days
                                  .where((d) => d.weekday == day.isoWeekday)
                                  .firstOrNull
                                  ?.isWorking ??
                              true;
                          return Material(
                            color: selected ? accent.soft : colors.surfaceMuted,
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: widget.enabled
                                  ? () => _toggleDay(day, state)
                                  : null,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                child: Text(
                                  day.shortLabel,
                                  style: AppTextStyle.base(
                                    14,
                                    color: selected ? accent.icon : colors.textColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
