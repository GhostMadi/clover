import 'package:auto_route/auto_route.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_snack_bar.dart';
import 'package:clover/core/shared/app_switch.dart';
import 'package:clover/feature/_attendance_/shared/data/attendance_context_store.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_duty_roster.dart';
import 'package:clover/feature/_attendance_/shared/presentation/widget/attendance_screen_shell.dart';
import 'package:clover/feature/_attendance_/shared/presentation/widget/attendance_service_ui.dart';
import 'package:flutter/material.dart';

@RoutePage()
class AttendanceDutyRosterPage extends StatefulWidget {
  const AttendanceDutyRosterPage({super.key, required this.workplaceId});

  final String workplaceId;

  @override
  State<AttendanceDutyRosterPage> createState() => _AttendanceDutyRosterPageState();
}

class _AttendanceDutyRosterPageState extends State<AttendanceDutyRosterPage> {
  final _store = sl<AttendanceContextStore>();
  late AttendanceDutyRoster _roster;

  @override
  void initState() {
    super.initState();
    _roster = _store.snapshot.value?.workplaceById(widget.workplaceId)?.dutyRoster ??
        const AttendanceDutyRoster();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = attendanceServiceAccent(colors);
    final today = DateTime.now();
    final onDutyIds = _roster.onDutyFor(today);
    final accepted = (_store.snapshot.value?.workersFor(widget.workplaceId) ?? const [])
        .where((w) => w.isAccepted && !w.isArchived)
        .toList(growable: false);

    return AttendanceScreenShell(
      title: 'Дежурные',
      showSave: true,
      onSaveTap: _save,
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 8, 16, AttendanceScreenShell.scrollBottomGap(context)),
        children: [
          Text(
            'Очередь по рабочим дням. Дежурство — подсказка для команды, не блокирует отметку.',
            style: AppTextStyle.base(14, color: colors.subTextColor),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: accent.soft,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: accent.icon.withValues(alpha: 0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Сегодня дежурит', style: AppTextStyle.base(13, color: colors.subTextColor)),
                const SizedBox(height: 6),
                Text(
                  onDutyIds.isEmpty
                      ? 'Сегодня не рабочий день или очередь пуста'
                      : onDutyIds
                          .map((id) => accepted.where((w) => w.id == id).map((w) => w.displayName).firstOrNull ?? id)
                          .join(', '),
                  style: AppTextStyle.base(17, color: colors.textColor, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  'Инфо для команды + уведомление. Не блокирует отметку.',
                  style: AppTextStyle.base(13, color: colors.subTextColor, height: 1.35),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('Рабочие дни', style: AppTextStyle.base(16, color: colors.textColor, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(7, (i) {
              final day = i + 1;
              final selected = _roster.workingWeekdays.contains(day);
              return FilterChip(
                label: Text(day.labelRuShort),
                selected: selected,
                onSelected: (_) => setState(() {
                  final days = Set<int>.from(_roster.workingWeekdays);
                  if (selected) {
                    days.remove(day);
                  } else {
                    days.add(day);
                  }
                  _roster = _roster.copyWith(workingWeekdays: days);
                }),
              );
            }),
          ),
          const SizedBox(height: 20),
          Text('Очередь', style: AppTextStyle.base(16, color: colors.textColor, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          for (final worker in accepted) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${worker.displayName} ${worker.username}',
                    style: AppTextStyle.base(15, color: colors.textColor),
                  ),
                ),
                AppSwitch(
                  value: _roster.workerIds.contains(worker.id),
                  service: kAttendanceService,
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
              ],
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  void _save() {
    _store.updateDutyRoster(workplaceId: widget.workplaceId, roster: _roster);
    AppSnackBar.show(
      context,
      message: 'Сохранено · команде уйдёт уведомление о дежурных',
      kind: AppSnackBarKind.success,
    );
    context.router.maybePop();
  }
}
