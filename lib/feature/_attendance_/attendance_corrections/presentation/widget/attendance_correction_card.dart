import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_correction_request.dart';
import 'package:clover/feature/_attendance_/shared/presentation/widget/attendance_approve_reject_row.dart';
import 'package:clover/feature/_attendance_/shared/presentation/widget/attendance_section_title.dart';
import 'package:clover/feature/_attendance_/shared/presentation/widget/attendance_service_ui.dart';
import 'package:flutter/material.dart';

class AttendanceCorrectionCard extends StatelessWidget {
  const AttendanceCorrectionCard({
    super.key,
    required this.item,
    this.onApprove,
    this.onReject,
  });

  final AttendanceCorrectionRequest item;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  static String formatTime(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')} '
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = attendanceServiceAccent(colors);
    final yellow = attendanceYellowAccent(colors);
    final statusColor = switch (item.status) {
      AttendanceCorrectionStatus.pending => yellow.icon,
      AttendanceCorrectionStatus.approved => accent.icon,
      AttendanceCorrectionStatus.rejected => colors.destructive,
    };

    final punched = item.punchedAt;
    final proposed = item.proposedPunchedAt;
    final note = item.note?.trim();
    final timeLine = [
      if (punched != null) 'сейчас ${formatTime(punched)}',
      if (proposed != null) '→ ${formatTime(proposed)}',
    ].join(' ');

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
                    child: Icon(AppIcons.editOutlined.icon, color: accent.icon, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.workerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyle.base(15, color: colors.textColor, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.punchKindLabelRu,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyle.base(12, color: colors.subTextColor, fontWeight: FontWeight.w600),
                        ),
                        if (timeLine.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            timeLine,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyle.base(12, color: colors.subTextColor),
                          ),
                        ],
                        if (note != null && note.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            note,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyle.base(12, color: colors.subTextColor),
                          ),
                        ],
                      ],
                    ),
                  ),
                  AttendanceStatusChip(label: item.status.labelRu, color: statusColor),
                ],
              ),
              if (item.status == AttendanceCorrectionStatus.pending &&
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
