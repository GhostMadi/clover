import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_outlined_button.dart';
import 'package:clover/core/shared/app_snack_bar.dart';
import 'package:clover/core/shared/app_tab.dart';
import 'package:clover/feature/_attendance_/attendance_overtime/presentation/cubit/attendance_overtime_cubit.dart';
import 'package:clover/feature/_attendance_/shared/data/attendance_context_store.dart';
import 'package:clover/feature/_attendance_/shared/data/attendance_error.dart';
import 'package:clover/feature/_attendance_/shared/data/attendance_outbox.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_day_time.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_overtime_entry.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_punch_record.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_snapshot.dart';
import 'package:clover/feature/_attendance_/shared/presentation/widget/attendance_screen_shell.dart';
import 'package:clover/feature/_attendance_/shared/presentation/widget/attendance_service_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

@RoutePage()
class AttendanceOvertimePage extends StatefulWidget {
  const AttendanceOvertimePage({super.key, required this.workplaceId});

  final String workplaceId;

  @override
  State<AttendanceOvertimePage> createState() => _AttendanceOvertimePageState();
}

class _AttendanceOvertimePageState extends State<AttendanceOvertimePage> {
  late final AttendanceOvertimeCubit _cubit;
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _cubit = sl<AttendanceOvertimeCubit>()..bind(widget.workplaceId);
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AttendanceOvertimeCubit, AttendanceOvertimeState>(
      bloc: _cubit,
      builder: (context, state) {
        final all = state is AttendanceOvertimeLoaded
            ? state.entries
            : const <AttendanceOvertimeEntry>[];
        final pending = all.where((e) => e.status == AttendanceOvertimeStatus.pending).toList();
        final approved = all.where((e) => e.status == AttendanceOvertimeStatus.approved).toList();
        final rejected = all.where((e) => e.status == AttendanceOvertimeStatus.rejected).toList();
        final list = switch (_tabIndex) {
          1 => approved,
          2 => rejected,
          _ => pending,
        };

        final colors = context.colors;
        final accent = attendanceServiceAccent(colors);
        final yellow = attendanceYellowAccent(colors);
        final store = sl<AttendanceContextStore>();
        final snap = store.snapshot.value;
        final selfId = store.selfWorkerId();
        final workplace = snap?.workplaceById(widget.workplaceId);
        final suggestedHours = _lateClockOutHours(
          snap: snap,
          workplaceId: widget.workplaceId,
          workerId: selfId,
          scheduledOut: workplace?.clockOutScheduledTime,
        );

        return AttendanceScreenShell(
          title: 'Переработка',
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, AttendanceScreenShell.scrollBottomGap(context)),
                  children: [
                    Text(
                      'Поздний «Ушёл» сам по себе не даёт денег. Сначала заявка, потом ваше решение.',
                      style: AppTextStyle.base(14, color: colors.subTextColor, height: 1.35),
                    ),
                    const SizedBox(height: 14),
                    _OvertimePipeline(accent: accent, yellow: yellow),
                    const SizedBox(height: 16),
                    if (suggestedHours != null && suggestedHours > 0)
                      _SuggestionCard(
                        hours: suggestedHours,
                        onCreateRequest: () async {
                          try {
                            final result = await _cubit.addOvertimeRequest(
                              AttendanceOvertimeEntry(
                                id: 'ot_${DateTime.now().millisecondsSinceEpoch}',
                                workplaceId: widget.workplaceId,
                                workerId: selfId,
                                workerName: snap?.profileDisplayNames[selfId] ?? 'Вы',
                                date: DateTime.now(),
                                hours: suggestedHours,
                                status: AttendanceOvertimeStatus.pending,
                              ),
                            );
                            if (!context.mounted) return;
                            setState(() => _tabIndex = 0);
                            AppSnackBar.show(
                              context,
                              message: result == AttendancePersistResult.queued
                                  ? 'Сохранено локально, синхронизируется'
                                  : 'Заявка создана · ждёт утверждения',
                              kind: AppSnackBarKind.success,
                            );
                          } catch (e) {
                            if (!context.mounted) return;
                            final msg = e is AttendanceException ? e.userMessage : 'Не удалось создать заявку';
                            AppSnackBar.show(context, message: msg, kind: AppSnackBarKind.error);
                          }
                        },
                      )
                    else
                      Text(
                        'Подсказка появится после «Ушёл» позже графика компании.',
                        style: AppTextStyle.base(13, color: colors.subTextColor, height: 1.35),
                      ),
                    const SizedBox(height: 16),
                    AppTab(
                      tabs: [
                        'Ожидают · ${pending.length}',
                        'В ЗП · ${approved.length}',
                        'Отклонены · ${rejected.length}',
                      ],
                      currentIndex: _tabIndex,
                      onTabChanged: (i) => setState(() => _tabIndex = i),
                    ),
                    const SizedBox(height: 12),
                    if (list.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 24),
                        child: Text(
                          switch (_tabIndex) {
                            1 => 'Пока нет утверждённых — в зарплату нечего добавлять.',
                            2 => 'Отклонённых заявок нет.',
                            _ => 'Нет заявок на утверждение.',
                          },
                          textAlign: TextAlign.center,
                          style: AppTextStyle.base(14, color: colors.subTextColor),
                        ),
                      )
                    else
                      for (final entry in list)
                        _OvertimeCard(entry: entry, cubit: _cubit),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Hours after scheduled clock-out from today's last non-cancelled clock_out.
  int? _lateClockOutHours({
    required AttendanceSnapshot? snap,
    required String workplaceId,
    required String workerId,
    required AttendanceDayTime? scheduledOut,
  }) {
    if (snap == null || scheduledOut == null) return null;
    final today = DateTime.now();
    final dayStart = DateTime(today.year, today.month, today.day);
    AttendancePunchRecord? lastOut;
    for (final p in snap.punchHistory) {
      if (p.workplaceId != workplaceId || p.workerId != workerId) continue;
      if (p.cancelled || !p.type.isClockOut) continue;
      if (p.at.isBefore(dayStart)) continue;
      if (lastOut == null || p.at.isAfter(lastOut.at)) lastOut = p;
    }
    if (lastOut == null) return null;
    final scheduled = DateTime(today.year, today.month, today.day, scheduledOut.hour, scheduledOut.minute);
    final diffMin = lastOut.at.difference(scheduled).inMinutes;
    if (diffMin < 30) return null;
    return ((diffMin + 29) ~/ 60).clamp(1, 12);
  }
}

class _OvertimePipeline extends StatelessWidget {
  const _OvertimePipeline({required this.accent, required this.yellow});

  final AppServiceAccent accent;
  final ({Color surface, Color icon}) yellow;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Как считается доплата',
            style: AppTextStyle.base(14, color: colors.textColor, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _PipeStep(label: 'Подсказка\n/ заявка', color: yellow.icon)),
              Icon(AppIcons.chevronRight.icon, size: 16, color: colors.iconMuted),
              Expanded(child: _PipeStep(label: 'Ожидает\nваш ok', color: yellow.icon)),
              Icon(AppIcons.chevronRight.icon, size: 16, color: colors.iconMuted),
              Expanded(child: _PipeStep(label: 'В зарплате\nтолько ok', color: accent.icon)),
            ],
          ),
        ],
      ),
    );
  }
}

class _PipeStep extends StatelessWidget {
  const _PipeStep({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: AppTextStyle.base(11, color: context.colors.subTextColor, height: 1.2),
        ),
      ],
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({required this.hours, required this.onCreateRequest});

  final int hours;
  final FutureOr<void> Function() onCreateRequest;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final yellow = attendanceYellowAccent(colors);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: yellow.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: yellow.icon.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(AppIcons.accessTime.icon, color: yellow.icon, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Подсказка (ещё не деньги)',
                  style: AppTextStyle.base(14, color: colors.textColor, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Уход позже графика · ~$hours ч. Это не доплата, пока нет заявки и утверждения.',
            style: AppTextStyle.base(13, color: colors.subTextColor, height: 1.35),
          ),
          const SizedBox(height: 12),
          AttendancePrimaryButton(
            text: 'Создать заявку на $hours ч',
            height: 44,
            isExpanded: true,
            onTap: onCreateRequest,
          ),
        ],
      ),
    );
  }
}

class _OvertimeCard extends StatelessWidget {
  const _OvertimeCard({required this.entry, required this.cubit});

  final AttendanceOvertimeEntry entry;
  final AttendanceOvertimeCubit cubit;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = attendanceServiceAccent(colors);
    final yellow = attendanceYellowAccent(colors);
    final statusColor = switch (entry.status) {
      AttendanceOvertimeStatus.pending => yellow.icon,
      AttendanceOvertimeStatus.approved => accent.icon,
      AttendanceOvertimeStatus.rejected => colors.destructive,
    };
    final statusHint = switch (entry.status) {
      AttendanceOvertimeStatus.pending => 'Пока не в зарплате',
      AttendanceOvertimeStatus.approved => 'Учтено в расчёте ЗП',
      AttendanceOvertimeStatus.rejected => 'Доплаты не будет',
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  entry.workerName,
                  style: AppTextStyle.base(16, color: colors.textColor, fontWeight: FontWeight.w700),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  entry.status.labelRu,
                  style: AppTextStyle.base(12, color: statusColor, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${entry.date.day.toString().padLeft(2, '0')}.${entry.date.month.toString().padLeft(2, '0')} · ${entry.hours} ч',
            style: AppTextStyle.base(14, color: colors.subTextColor),
          ),
          const SizedBox(height: 2),
          Text(statusHint, style: AppTextStyle.base(12, color: colors.subTextColor)),
          if (entry.status == AttendanceOvertimeStatus.pending) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AttendancePrimaryButton(
                    text: 'Утвердить',
                    height: 44,
                    onTap: () async {
                      try {
                        final result = await cubit.setOvertimeStatus(
                          entryId: entry.id,
                          status: AttendanceOvertimeStatus.approved,
                        );
                        if (!context.mounted) return;
                        AppSnackBar.show(
                          context,
                          message: result == AttendancePersistResult.queued
                              ? 'Сохранено локально, синхронизируется'
                              : 'В зарплате появится доплата',
                          kind: AppSnackBarKind.success,
                        );
                      } catch (e) {
                        if (!context.mounted) return;
                        final msg = e is AttendanceException ? e.userMessage : 'Не удалось утвердить';
                        AppSnackBar.show(context, message: msg, kind: AppSnackBarKind.error);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppOutlinedButton(
                    text: 'Отклонить',
                    height: 44,
                    service: kAttendanceService,
                    onTap: () async {
                      try {
                        final result = await cubit.setOvertimeStatus(
                          entryId: entry.id,
                          status: AttendanceOvertimeStatus.rejected,
                        );
                        if (!context.mounted) return;
                        AppSnackBar.show(
                          context,
                          message: result == AttendancePersistResult.queued
                              ? 'Сохранено локально, синхронизируется'
                              : 'Отклонено · без доплаты',
                          kind: result == AttendancePersistResult.queued
                              ? AppSnackBarKind.success
                              : AppSnackBarKind.info,
                        );
                      } catch (e) {
                        if (!context.mounted) return;
                        final msg = e is AttendanceException ? e.userMessage : 'Не удалось отклонить';
                        AppSnackBar.show(context, message: msg, kind: AppSnackBarKind.error);
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
