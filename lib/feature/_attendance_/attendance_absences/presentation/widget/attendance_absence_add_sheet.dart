import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_snack_bar.dart';
import 'package:clover/feature/_attendance_/attendance_absences/presentation/cubit/attendance_absences_cubit.dart';
import 'package:clover/feature/_attendance_/shared/data/attendance_error.dart';
import 'package:clover/feature/_attendance_/shared/data/attendance_outbox.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_absence.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_worker.dart';
import 'package:clover/feature/_attendance_/shared/presentation/widget/attendance_service_ui.dart';
import 'package:flutter/material.dart';

abstract final class AttendanceAbsenceAddSheet {
  static Future<void> show(
    BuildContext context, {
    required String workplaceId,
    required List<AttendanceWorkerListItem> workers,
    required AttendanceAbsencesCubit cubit,
  }) async {
    if (workers.isEmpty) {
      await AttendanceBottomSheet.show(
        context: context,
        title: 'Отсутствие',
        upperCaseTitle: false,
        showCloseButton: true,
        contentBottomSpacing: 8,
        content: Builder(
          builder: (sheetContext) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Нет активных работников',
                  style: AppTextStyle.base(14, color: sheetContext.colors.subTextColor),
                ),
                const SizedBox(height: 16),
                AttendancePrimaryButton(
                  text: 'Закрыть',
                  isExpanded: true,
                  height: 48,
                  onTap: () => Navigator.of(sheetContext).pop(),
                ),
              ],
            );
          },
        ),
      );
      return;
    }

    var kind = AttendanceAbsenceKind.dayOff;
    var workerId = workers.first.id;
    final now = DateTime.now();

    await AttendanceBottomSheet.show(
      context: context,
      title: 'Отсутствие',
      upperCaseTitle: false,
      showCloseButton: true,
      contentBottomSpacing: 8,
      content: StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          final colors = sheetContext.colors;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Работник',
                style: AppTextStyle.base(13, color: colors.subTextColor, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              for (final w in workers)
                AttendanceServiceTile(
                  title: w.displayName,
                  selected: w.id == workerId,
                  onTap: () => setSheetState(() => workerId = w.id),
                ),
              const SizedBox(height: 12),
              Text(
                'Тип',
                style: AppTextStyle.base(13, color: colors.subTextColor, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              for (final k in AttendanceAbsenceKind.values)
                AttendanceServiceTile(
                  title: k.labelRu,
                  selected: k == kind,
                  onTap: () => setSheetState(() => kind = k),
                ),
              const SizedBox(height: 16),
              AttendancePrimaryButton(
                text: 'Сохранить',
                isExpanded: true,
                height: 48,
                onTap: () async {
                  try {
                    final result = await cubit.addAbsence(
                      AttendanceAbsenceEntry(
                        id: 'abs_${DateTime.now().millisecondsSinceEpoch}',
                        workplaceId: workplaceId,
                        workerId: workerId,
                        kind: kind,
                        startDate: now,
                        endDate: now,
                      ),
                    );
                    if (!sheetContext.mounted) return;
                    Navigator.of(sheetContext).pop();
                    AppSnackBar.show(
                      context,
                      message: result == AttendancePersistResult.queued
                          ? 'Сохранено локально'
                          : 'Добавлено',
                      kind: AppSnackBarKind.success,
                    );
                  } catch (e) {
                    if (!sheetContext.mounted) return;
                    final msg = e is AttendanceException ? e.userMessage : 'Не удалось сохранить';
                    AppSnackBar.show(context, message: msg, kind: AppSnackBarKind.error);
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
