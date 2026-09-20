import 'package:auto_route/auto_route.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_snack_bar.dart';
import 'package:clover/feature/_attendance_/attendance_overtime/presentation/cubit/attendance_overtime_cubit.dart';
import 'package:clover/feature/_attendance_/attendance_overtime/presentation/widget/attendance_overtime_entry_card.dart';
import 'package:clover/feature/_attendance_/attendance_overtime/presentation/widget/attendance_overtime_suggestion_card.dart';
import 'package:clover/feature/_attendance_/shared/data/attendance_context_store.dart';
import 'package:clover/feature/_attendance_/shared/data/attendance_error.dart';
import 'package:clover/feature/_attendance_/shared/data/attendance_outbox.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_day_time.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_overtime_entry.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_punch_record.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_snapshot.dart';
import 'package:clover/feature/_attendance_/shared/presentation/widget/attendance_screen_shell.dart';
import 'package:clover/feature/_attendance_/shared/presentation/widget/attendance_section_title.dart';
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

  Future<void> _setStatus(AttendanceOvertimeEntry entry, AttendanceOvertimeStatus status) async {
    try {
      final result = await _cubit.setOvertimeStatus(entryId: entry.id, status: status);
      if (!mounted) return;
      final okMsg = status == AttendanceOvertimeStatus.approved ? 'Утверждено' : 'Отклонено';
      AppSnackBar.show(
        context,
        message: result == AttendancePersistResult.queued ? 'Сохранено локально' : okMsg,
        kind: status == AttendanceOvertimeStatus.approved
            ? AppSnackBarKind.success
            : AppSnackBarKind.info,
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e is AttendanceException ? e.userMessage : 'Не удалось сохранить';
      AppSnackBar.show(context, message: msg, kind: AppSnackBarKind.error);
    }
  }

  Future<void> _createSuggestion(int hours, String selfId, AttendanceSnapshot? snap) async {
    try {
      final result = await _cubit.addOvertimeRequest(
        AttendanceOvertimeEntry(
          id: 'ot_${DateTime.now().millisecondsSinceEpoch}',
          workplaceId: widget.workplaceId,
          workerId: selfId,
          workerName: snap?.profileDisplayNames[selfId] ?? 'Вы',
          date: DateTime.now(),
          hours: hours,
          status: AttendanceOvertimeStatus.pending,
        ),
      );
      if (!mounted) return;
      AppSnackBar.show(
        context,
        message: result == AttendancePersistResult.queued ? 'Сохранено локально' : 'Заявка создана',
        kind: AppSnackBarKind.success,
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e is AttendanceException ? e.userMessage : 'Не удалось создать заявку';
      AppSnackBar.show(context, message: msg, kind: AppSnackBarKind.error);
    }
  }

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
        final colors = context.colors;
        final empty = pending.isEmpty && approved.isEmpty && rejected.isEmpty && suggestedHours == null;

        return AttendanceScreenShell(
          title: 'Переработка',
          body: ListView(
            padding: EdgeInsets.fromLTRB(16, 0, 16, AttendanceScreenShell.scrollBottomGap(context)),
            children: [
              if (suggestedHours != null && suggestedHours > 0) ...[
                AttendanceOvertimeSuggestionCard(
                  hours: suggestedHours,
                  onCreateRequest: () => _createSuggestion(suggestedHours, selfId, snap),
                ),
                const SizedBox(height: 16),
              ],
              if (empty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Text(
                    'Нет заявок на переработку',
                    textAlign: TextAlign.center,
                    style: AppTextStyle.base(14, color: colors.subTextColor),
                  ),
                )
              else ...[
                if (pending.isNotEmpty) ...[
                  const AttendanceSectionTitle('Ожидают'),
                  const SizedBox(height: 8),
                  for (final entry in pending) ...[
                    AttendanceOvertimeEntryCard(
                      entry: entry,
                      onApprove: () => _setStatus(entry, AttendanceOvertimeStatus.approved),
                      onReject: () => _setStatus(entry, AttendanceOvertimeStatus.rejected),
                    ),
                    const SizedBox(height: 8),
                  ],
                  const SizedBox(height: 12),
                ],
                if (approved.isNotEmpty) ...[
                  const AttendanceSectionTitle('В зарплате'),
                  const SizedBox(height: 8),
                  for (final entry in approved) ...[
                    AttendanceOvertimeEntryCard(entry: entry),
                    const SizedBox(height: 8),
                  ],
                  if (rejected.isNotEmpty) const SizedBox(height: 12),
                ],
                if (rejected.isNotEmpty) ...[
                  const AttendanceSectionTitle('Отклонены'),
                  const SizedBox(height: 8),
                  for (final entry in rejected) ...[
                    AttendanceOvertimeEntryCard(entry: entry),
                    const SizedBox(height: 8),
                  ],
                ],
              ],
            ],
          ),
        );
      },
    );
  }
}
