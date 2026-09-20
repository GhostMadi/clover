import 'package:clover/core/shared/app_snack_bar.dart';
import 'package:clover/core/shared/app_switch.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_custom_punch_config.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_day_time.dart';
import 'package:clover/feature/_attendance_/shared/presentation/widget/attendance_service_ui.dart';
import 'package:clover/feature/_attendance_/shared/presentation/widget/attendance_time_picker_field.dart';
import 'package:flutter/material.dart';

abstract final class AttendancePunchAddSheet {
  static Future<AttendanceCustomPunchConfig?> show(
    BuildContext context, {
    required List<AttendanceCustomPunchConfig> existing,
  }) async {
    final labelController = TextEditingController();
    var scheduleEnabled = false;
    AttendanceDayTime? scheduledTime;

    try {
      return await AttendanceBottomSheet.show<AttendanceCustomPunchConfig>(
        context: context,
        title: 'Своя отметка',
        upperCaseTitle: false,
        showCloseButton: true,
        contentBottomSpacing: 8,
        content: StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AttendanceField(
                  labelText: 'Название',
                  hintText: 'Обед',
                  controller: labelController,
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 12),
                AppSwitchRow(
                  title: 'Время',
                  value: scheduleEnabled,
                  service: kAttendanceService,
                  onChanged: (v) => setSheetState(() {
                    scheduleEnabled = v;
                    if (!v) {
                      scheduledTime = null;
                    } else {
                      scheduledTime ??= const AttendanceDayTime(hour: 12, minute: 0);
                    }
                  }),
                ),
                if (scheduleEnabled) ...[
                  const SizedBox(height: 12),
                  AttendanceTimePickerField(
                    enabled: true,
                    time: scheduledTime,
                    onChanged: (t) => setSheetState(() => scheduledTime = t),
                  ),
                ],
                const SizedBox(height: 16),
                AttendancePrimaryButton(
                  text: 'Добавить',
                  isExpanded: true,
                  height: 48,
                  onTap: () {
                    final label = labelController.text.trim();
                    if (label.isEmpty) return;
                    if (existing.any((e) => e.label.toLowerCase() == label.toLowerCase())) {
                      AppSnackBar.show(sheetContext, message: 'Уже есть', kind: AppSnackBarKind.info);
                      return;
                    }
                    Navigator.of(sheetContext).pop(
                      AttendanceCustomPunchConfig(
                        label: label,
                        scheduledTime: scheduleEnabled ? scheduledTime : null,
                      ),
                    );
                  },
                ),
              ],
            );
          },
        ),
      );
    } finally {
      Future<void>.delayed(const Duration(milliseconds: 400), labelController.dispose);
    }
  }
}
