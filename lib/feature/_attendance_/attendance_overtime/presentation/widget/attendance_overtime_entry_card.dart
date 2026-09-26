import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_overtime_entry.dart';
import 'package:clover/feature/_attendance_/shared/presentation/widget/attendance_approve_reject_row.dart';
import 'package:clover/feature/_attendance_/shared/presentation/widget/attendance_section_title.dart';
import 'package:clover/feature/_attendance_/shared/presentation/widget/attendance_service_ui.dart';
import 'package:flutter/material.dart';
import 'package:clover/feature/_attendance_/shared/attendance_l10n.dart';
import 'package:clover/core/extension/context.dart';

class AttendanceOvertimeEntryCard extends StatelessWidget {
  const AttendanceOvertimeEntryCard({
    super.key,
    required this.entry,
    this.onApprove,
    this.onReject,
  });

  final AttendanceOvertimeEntry entry;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

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
    final date =
        '${entry.date.day.toString().padLeft(2, '0')}.${entry.date.month.toString().padLeft(2, '0')}';

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: accent.soft,
                    child: Icon(AppIcons.schedule.icon, color: accent.icon, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.workerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyle.base(15, color: colors.textColor, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          context.l10n.attendance_overtime_hours_line(date, '${entry.hours}'),
                          style: AppTextStyle.base(12, color: colors.subTextColor, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  AttendanceStatusChip(label: entry.status.label(context.l10n), color: statusColor),
                ],
              ),
              if (entry.status == AttendanceOvertimeStatus.pending &&
                  onApprove != null &&
                  onReject != null) ...[
                const SizedBox(height: 12),
                AttendanceApproveRejectRow(onApprove: onApprove!, onReject: onReject!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
