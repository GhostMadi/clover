import 'package:auto_route/auto_route.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_snack_bar.dart';
import 'package:clover/core/shared/app_switch.dart';
import 'package:clover/feature/_attendance_/attendance_duty_roster/presentation/widget/attendance_duty_queue_tile.dart';
import 'package:clover/feature/_attendance_/attendance_duty_roster/presentation/widget/attendance_duty_today_card.dart';
import 'package:clover/feature/_attendance_/attendance_duty_roster/presentation/widget/attendance_duty_weekday_chips.dart';
import 'package:clover/feature/_attendance_/attendance_workplace_settings/presentation/cubit/attendance_workplace_settings_cubit.dart';
import 'package:clover/feature/_attendance_/shared/data/attendance_error.dart';
import 'package:clover/feature/_attendance_/shared/data/attendance_outbox.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_duty_roster.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_worker.dart';
import 'package:clover/feature/_attendance_/shared/presentation/widget/attendance_screen_shell.dart';
import 'package:clover/feature/_attendance_/shared/presentation/widget/attendance_service_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

@RoutePage()
class AttendanceDutyRosterPage extends StatefulWidget {
  const AttendanceDutyRosterPage({super.key, required this.workplaceId});

  final String workplaceId;

  @override
  State<AttendanceDutyRosterPage> createState() => _AttendanceDutyRosterPageState();
}

class _AttendanceDutyRosterPageState extends State<AttendanceDutyRosterPage> {
  late final AttendanceWorkplaceSettingsCubit _cubit;
  late AttendanceDutyRoster _roster;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _cubit = sl<AttendanceWorkplaceSettingsCubit>()..bind(widget.workplaceId);
    final ready = _cubit.state is AttendanceWorkplaceSettingsReady
        ? _cubit.state as AttendanceWorkplaceSettingsReady
        : null;
    _roster = ready?.workplace.dutyRoster ?? const AttendanceDutyRoster();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  String _username(AttendanceWorkerListItem worker) {
    final raw = worker.username.trim();
    if (raw.isEmpty) return 'Аккаунт Clover';
    return raw.startsWith('@') ? raw : '@$raw';
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final result = await _cubit.updateDutyRoster(_roster);
      if (!mounted) return;
      AppSnackBar.show(
        context,
        message: result == AttendancePersistResult.queued ? 'Сохранено локально' : 'Сохранено',
        kind: AppSnackBarKind.success,
      );
      context.router.maybePop();
    } catch (e) {
      if (!mounted) return;
      final msg = e is AttendanceException ? e.userMessage : 'Не удалось сохранить';
      AppSnackBar.show(context, message: msg, kind: AppSnackBarKind.error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final today = DateTime.now();
    final onDutyIds = _roster.onDutyFor(today);

    return BlocBuilder<AttendanceWorkplaceSettingsCubit, AttendanceWorkplaceSettingsState>(
      bloc: _cubit,
      builder: (context, state) {
        final ready = state is AttendanceWorkplaceSettingsReady ? state : null;
        final accepted = (ready?.snapshot.workersFor(widget.workplaceId) ?? const <AttendanceWorkerListItem>[])
            .where((w) => w.isAccepted && !w.isArchived)
            .toList(growable: false);
        final dutyOnly = ready?.workplace.dutyOnlyPunch ?? false;
        final todayNames = onDutyIds
            .map(
              (id) => accepted.where((w) => w.id == id).map((w) => w.displayName).firstOrNull ?? id,
            )
            .toList(growable: false);

        return AttendanceScreenShell(
          title: 'Дежурные',
          showSave: true,
          isSaving: _saving,
          onSaveTap: _save,
          body: ListView(
            padding: EdgeInsets.fromLTRB(16, 0, 16, AttendanceScreenShell.scrollBottomGap(context)),
            children: [
              AttendanceDutyTodayCard(names: todayNames, strictMode: dutyOnly),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Только дежурный отмечает',
                      style: AppTextStyle.base(15, color: colors.textColor, fontWeight: FontWeight.w600),
                    ),
                  ),
                  AppSwitch(
                    value: dutyOnly,
                    service: kAttendanceService,
                    onChanged: (v) async {
                      try {
                        await _cubit.setDutyOnlyPunch(v);
                      } catch (e) {
                        if (!context.mounted) return;
                        final msg = e is AttendanceException ? e.userMessage : 'Не удалось сохранить';
                        AppSnackBar.show(context, message: msg, kind: AppSnackBarKind.error);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Рабочие дни',
                style: AppTextStyle.base(14, color: colors.subTextColor, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              AttendanceDutyWeekdayChips(
                selected: _roster.workingWeekdays,
                onChanged: (days) => setState(() => _roster = _roster.copyWith(workingWeekdays: days)),
              ),
              const SizedBox(height: 20),
              Text(
                'Очередь',
                style: AppTextStyle.base(14, color: colors.subTextColor, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              if (accepted.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Сначала добавьте работников',
                    style: AppTextStyle.base(14, color: colors.subTextColor),
                  ),
                )
              else
                for (final worker in accepted) ...[
                  AttendanceDutyQueueTile(
                    title: worker.displayName,
                    subtitle: _username(worker),
                    value: _roster.workerIds.contains(worker.id),
                    onChanged: (v) => setState(() {
                      final ids = List<String>.from(_roster.workerIds);
                      if (v) {
                        if (!ids.contains(worker.id)) ids.add(worker.id);
                      } else {
                        ids.remove(worker.id);
                      }
                      _roster = _roster.copyWith(workerIds: ids);
                    }),
                  ),
                  const SizedBox(height: 8),
                ],
            ],
          ),
        );
      },
    );
  }
}
