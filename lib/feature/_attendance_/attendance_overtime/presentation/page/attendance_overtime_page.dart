import 'package:auto_route/auto_route.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/app_service_accent.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_outlined_button.dart';
import 'package:clover/core/shared/app_snack_bar.dart';
import 'package:clover/core/shared/app_tab.dart';
import 'package:clover/feature/_attendance_/shared/data/attendance_context_store.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_overtime_entry.dart';
import 'package:clover/feature/_attendance_/shared/presentation/widget/attendance_screen_shell.dart';
import 'package:clover/feature/_attendance_/shared/presentation/widget/attendance_service_ui.dart';
import 'package:flutter/material.dart';

@RoutePage()
class AttendanceOvertimePage extends StatefulWidget {
  const AttendanceOvertimePage({super.key, required this.workplaceId});

  final String workplaceId;

  @override
  State<AttendanceOvertimePage> createState() => _AttendanceOvertimePageState();
}

class _AttendanceOvertimePageState extends State<AttendanceOvertimePage> {
  final _store = sl<AttendanceContextStore>();
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: _store.snapshot,
      builder: (context, snap, _) {
        final all = snap?.overtimeEntries.where((e) => e.workplaceId == widget.workplaceId).toList() ??
            const <AttendanceOvertimeEntry>[];
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
                    _SuggestionDemoCard(
                      onCreateRequest: () {
                        _store.addOvertimeRequest(
                          AttendanceOvertimeEntry(
                            id: 'ot_${DateTime.now().millisecondsSinceEpoch}',
                            workplaceId: widget.workplaceId,
                            workerId: 'worker_you',
                            workerName: 'Вы',
                            date: DateTime.now(),
                            hours: 2,
                            status: AttendanceOvertimeStatus.pending,
                          ),
                        );
                        setState(() => _tabIndex = 0);
                        AppSnackBar.show(
                          context,
                          message: 'Заявка создана · ждёт утверждения',
                          kind: AppSnackBarKind.success,
                        );
                      },
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
                        _OvertimeCard(entry: entry, store: _store),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
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

class _SuggestionDemoCard extends StatelessWidget {
  const _SuggestionDemoCard({required this.onCreateRequest});

  final VoidCallback onCreateRequest;

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
            'У «Вы» уход позже графика · ~2 ч. Это не доплата, пока нет заявки и утверждения.',
            style: AppTextStyle.base(13, color: colors.subTextColor, height: 1.35),
          ),
          const SizedBox(height: 12),
          AttendancePrimaryButton(
            text: 'Создать заявку на 2 ч',
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
  const _OvertimeCard({required this.entry, required this.store});

  final AttendanceOvertimeEntry entry;
  final AttendanceContextStore store;

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
                    onTap: () {
                      store.setOvertimeStatus(entryId: entry.id, status: AttendanceOvertimeStatus.approved);
                      AppSnackBar.show(context, message: 'В зарплате появится доплата', kind: AppSnackBarKind.success);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppOutlinedButton(
                    text: 'Отклонить',
                    height: 44,
                    service: kAttendanceService,
                    onTap: () {
                      store.setOvertimeStatus(entryId: entry.id, status: AttendanceOvertimeStatus.rejected);
                      AppSnackBar.show(context, message: 'Отклонено · без доплаты', kind: AppSnackBarKind.info);
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
