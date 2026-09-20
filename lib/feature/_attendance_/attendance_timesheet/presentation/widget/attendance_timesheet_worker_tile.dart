import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/feature/_attendance_/shared/presentation/widget/attendance_service_ui.dart';
import 'package:flutter/material.dart';

/// Строка часов в табеле.
class AttendanceTimesheetWorkerTile extends StatelessWidget {
  const AttendanceTimesheetWorkerTile({
    super.key,
    required this.name,
    required this.hoursLabel,
  });

  final String name;
  final String hoursLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = attendanceServiceAccent(colors);

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.border.withValues(alpha: 0.55)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: accent.soft,
                child: Icon(AppIcons.user.icon, color: accent.icon, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyle.base(15, color: colors.textColor, fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                hoursLabel,
                style: AppTextStyle.base(15, color: accent.icon, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
