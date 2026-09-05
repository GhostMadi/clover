import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_picker_common.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_day_time.dart';
import 'package:clover/feature/_attendance_/shared/presentation/widget/attendance_service_ui.dart';
import 'package:flutter/material.dart';

/// Поле выбора времени отметки (когда работник должен отметиться).
class AttendanceTimePickerField extends StatelessWidget {
  const AttendanceTimePickerField({
    super.key,
    this.label = 'Ожидается в',
    this.hint = 'Выберите время',
    required this.enabled,
    required this.time,
    required this.onChanged,
  });

  final String label;
  final String hint;
  final bool enabled;
  final AttendanceDayTime? time;
  final ValueChanged<AttendanceDayTime?> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = attendanceServiceAccent(colors);
    final hasValue = time != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            label,
            style: AppTextStyle.base(13, fontWeight: FontWeight.w600, color: colors.fieldLabel),
          ),
        ),
        Material(
          color: enabled ? colors.fieldBackground : colors.fieldBackgroundDisabled,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: enabled ? () => _pickTime(context) : null,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: hasValue ? accent.ctaBorder : colors.fieldBorder),
                boxShadow: [
                  BoxShadow(
                    color: colors.shadowDark.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(AppIcons.schedule.icon, size: 22, color: hasValue ? accent.icon : colors.fieldIcon),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      hasValue ? time!.labelRu : hint,
                      style: AppTextStyle.base(
                        16,
                        fontWeight: FontWeight.w500,
                        color: hasValue ? colors.fieldText : colors.fieldHint,
                      ),
                    ),
                  ),
                  if (hasValue && enabled)
                    GestureDetector(
                      onTap: () => onChanged(null),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(AppIcons.closeRounded.icon, size: 18, color: colors.subTextColor),
                      ),
                    )
                  else
                    Icon(
                      AppIcons.arrowDown.icon,
                      color: colors.subTextColor.withValues(alpha: 0.55),
                      size: 24,
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickTime(BuildContext context) async {
    var hour = time?.hour ?? 9;
    var minute = time?.minute ?? 0;

    final hours = List.generate(24, (i) => i.toString().padLeft(2, '0'));
    final minutes = List.generate(12, (i) => (i * 5).toString().padLeft(2, '0'));

    await AttendanceBottomSheet.show(
      context: context,
      title: label,
      content: StatefulBuilder(
        builder: (context, setSheetState) {
          final minuteIndex = (minute ~/ 5).clamp(0, minutes.length - 1);

          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppPickerWheel(
                width: 72,
                items: hours,
                selectedIndex: hour.clamp(0, 23),
                service: kAttendanceService,
                onSelectedIndexChanged: (i) => setSheetState(() => hour = i),
              ),
              Text(':', style: AppTextStyle.base(22, color: context.colors.textColor, fontWeight: FontWeight.w700)),
              AppPickerWheel(
                width: 72,
                items: minutes,
                selectedIndex: minuteIndex,
                service: kAttendanceService,
                onSelectedIndexChanged: (i) => setSheetState(() => minute = i * 5),
              ),
            ],
          );
        },
      ),
      actions: [
        AttendancePrimaryButton(
          text: 'Готово',
          isExpanded: true,
          onTap: () {
            onChanged(AttendanceDayTime(hour: hour, minute: minute));
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
