import 'package:auto_route/auto_route.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_snack_bar.dart';
import 'package:clover/feature/_attendance_/shared/data/attendance_context_store.dart';
import 'package:clover/feature/_attendance_/shared/data/attendance_workers_mock.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_absence.dart';
import 'package:clover/feature/_attendance_/shared/presentation/widget/attendance_screen_shell.dart';
import 'package:clover/feature/_attendance_/shared/presentation/widget/attendance_service_ui.dart';
import 'package:flutter/material.dart';

@RoutePage()
class AttendanceAbsencesPage extends StatelessWidget {
  const AttendanceAbsencesPage({super.key, required this.workplaceId});

  final String workplaceId;

  @override
  Widget build(BuildContext context) {
    final store = sl<AttendanceContextStore>();

    return ValueListenableBuilder(
      valueListenable: store.snapshot,
      builder: (context, snap, _) {
        final absences = snap?.absences.where((e) => e.workplaceId == workplaceId).toList() ?? const [];
        absences.sort((a, b) => b.startDate.compareTo(a.startDate));
        final workers = snap?.workersFor(workplaceId).where((w) => w.isAccepted).toList() ?? const [];

        return AttendanceScreenShell(
          title: 'Отсутствия',
          showAdd: true,
          onAddTap: () => _showAdd(context, store, workers),
          body: ListView(
            padding: EdgeInsets.fromLTRB(16, 8, 16, AttendanceScreenShell.scrollBottomGap(context)),
            children: [
              Text(
                'Выходной, отпуск и больничный не считаются пропуском в зарплате.',
                style: AppTextStyle.base(14, color: context.colors.subTextColor),
              ),
              const SizedBox(height: 14),
              if (absences.isEmpty)
                Text('Нет записей', style: AppTextStyle.base(15, color: context.colors.subTextColor))
              else
                for (final entry in absences)
                  _AbsenceCard(
                    entry: entry,
                    workerName: snap?.workersFor(workplaceId)
                            .where((w) => w.id == entry.workerId)
                            .map((w) => w.displayName)
                            .firstOrNull ??
                        entry.workerId,
                  ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showAdd(
    BuildContext context,
    AttendanceContextStore store,
    List<AttendanceWorkerListItem> workers,
  ) {
    if (workers.isEmpty) {
      return AttendanceBottomSheet.show(
        context: context,
        title: 'Добавить отсутствие',
        content: Text(
          'Нет активных работников в компании.',
          style: AppTextStyle.base(15, color: context.colors.subTextColor),
        ),
        actions: [
          AttendancePrimaryButton(
            text: 'Понятно',
            isExpanded: true,
            onTap: () => Navigator.of(context).pop(),
          ),
        ],
      );
    }

    var kind = AttendanceAbsenceKind.dayOff;
    var workerId = workers.first.id;
    final now = DateTime.now();

    return AttendanceBottomSheet.show(
      context: context,
      title: 'Добавить отсутствие',
      content: StatefulBuilder(
        builder: (context, setState) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Работник', style: AppTextStyle.base(13, color: context.colors.subTextColor)),
              const SizedBox(height: 8),
              for (final w in workers)
                AttendanceServiceTile(
                  title: w.displayName,
                  selected: w.id == workerId,
                  onTap: () => setState(() => workerId = w.id),
                ),
              const SizedBox(height: 12),
              Text('Тип', style: AppTextStyle.base(13, color: context.colors.subTextColor)),
              const SizedBox(height: 8),
              for (final k in AttendanceAbsenceKind.values)
                AttendanceServiceTile(
                  title: k.labelRu,
                  selected: k == kind,
                  onTap: () => setState(() => kind = k),
                ),
            ],
          );
        },
      ),
      actions: [
        AttendancePrimaryButton(
          text: 'Сохранить',
          isExpanded: true,
          onTap: () {
            store.addAbsence(
              AttendanceAbsenceEntry(
                id: 'abs_${DateTime.now().millisecondsSinceEpoch}',
                workplaceId: workplaceId,
                workerId: workerId,
                kind: kind,
                startDate: now,
                endDate: now,
              ),
            );
            Navigator.of(context).pop();
            AppSnackBar.show(context, message: 'Отсутствие добавлено', kind: AppSnackBarKind.success);
          },
        ),
      ],
    );
  }
}

class _AbsenceCard extends StatelessWidget {
  const _AbsenceCard({required this.entry, required this.workerName});

  final AttendanceAbsenceEntry entry;
  final String workerName;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final fmt = (DateTime d) => '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(workerName, style: AppTextStyle.base(16, color: colors.textColor, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(
            '${entry.kind.labelRu} · ${fmt(entry.startDate)} — ${fmt(entry.endDate)}',
            style: AppTextStyle.base(14, color: colors.subTextColor),
          ),
          if (entry.note != null) ...[
            const SizedBox(height: 4),
            Text(entry.note!, style: AppTextStyle.base(13, color: colors.subTextColor)),
          ],
        ],
      ),
    );
  }
}

extension _FirstOrNullAbs<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    if (!it.moveNext()) return null;
    return it.current;
  }
}
