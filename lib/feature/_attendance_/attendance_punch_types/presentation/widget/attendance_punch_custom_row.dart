import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_switch.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_custom_punch_config.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_day_time.dart';
import 'package:clover/feature/_attendance_/shared/presentation/widget/attendance_service_ui.dart';
import 'package:clover/feature/_attendance_/shared/presentation/widget/attendance_time_picker_field.dart';
import 'package:flutter/material.dart';

/// Строка своей отметки.
class AttendancePunchCustomRow extends StatelessWidget {
  const AttendancePunchCustomRow({
    super.key,
    required this.config,
    required this.onScheduledTimeChanged,
    required this.onDelete,
  });

  final AttendanceCustomPunchConfig config;
  final ValueChanged<AttendanceDayTime?> onScheduledTimeChanged;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = attendanceServiceAccent(colors);
    final scheduleOn = config.hasScheduledTime;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      config.label,
                      style: AppTextStyle.base(15, color: colors.textColor, fontWeight: FontWeight.w700),
                    ),
                    if (scheduleOn)
                      Text(
                        'в ${config.scheduledTime!.labelRu}',
                        style: AppTextStyle.base(12, color: accent.icon, fontWeight: FontWeight.w600),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(AppIcons.delete.icon, color: colors.destructive, size: 22),
                onPressed: onDelete,
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: Text('Время', style: AppTextStyle.base(14, color: colors.subTextColor)),
              ),
              AppSwitch(
                value: scheduleOn,
                service: kAttendanceService,
                onChanged: (v) {
                  if (v) {
                    onScheduledTimeChanged(
                      config.scheduledTime ?? const AttendanceDayTime(hour: 12, minute: 0),
                    );
                  } else {
                    onScheduledTimeChanged(null);
                  }
                },
              ),
            ],
          ),
          if (scheduleOn) ...[
            const SizedBox(height: 10),
            AttendanceTimePickerField(
              enabled: true,
              time: config.scheduledTime,
              onChanged: onScheduledTimeChanged,
            ),
          ],
        ],
      ),
    );
  }
}
