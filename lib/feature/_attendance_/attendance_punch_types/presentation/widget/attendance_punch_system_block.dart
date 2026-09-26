import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_switch.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_day_time.dart';
import 'package:clover/feature/_attendance_/shared/presentation/widget/attendance_service_ui.dart';
import 'package:clover/feature/_attendance_/shared/presentation/widget/attendance_time_picker_field.dart';
import 'package:flutter/material.dart';
import 'package:clover/core/extension/context.dart';

/// Блок системной отметки (Пришёл / Ушёл).
class AttendancePunchSystemBlock extends StatelessWidget {
  const AttendancePunchSystemBlock({
    super.key,
    required this.title,
    required this.enabled,
    required this.scheduledTime,
    required this.onEnabledChanged,
    required this.onScheduledTimeChanged,
  });

  final String title;
  final bool enabled;
  final AttendanceDayTime? scheduledTime;
  final ValueChanged<bool> onEnabledChanged;
  final ValueChanged<AttendanceDayTime?> onScheduledTimeChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final scheduleOn = scheduledTime != null;

    return Padding(
      padding: EdgeInsets.fromLTRB(14, 12, 10, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyle.base(15, color: colors.textColor, fontWeight: FontWeight.w700),
                ),
              ),
              AppSwitch(value: enabled, service: kAttendanceService, onChanged: onEnabledChanged),
            ],
          ),
          if (enabled) ...[
            SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.l10n.common_time,
                    style: AppTextStyle.base(14, color: colors.subTextColor),
                  ),
                ),
                AppSwitch(
                  value: scheduleOn,
                  service: kAttendanceService,
                  onChanged: (v) {
                    if (v) {
                      onScheduledTimeChanged(
                        scheduledTime ?? const AttendanceDayTime(hour: 9, minute: 0),
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
                time: scheduledTime,
                onChanged: onScheduledTimeChanged,
              ),
            ],
          ],
        ],
      ),
    );
  }
}
