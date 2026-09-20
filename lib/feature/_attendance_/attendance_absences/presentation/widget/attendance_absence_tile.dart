import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_absence.dart';
import 'package:clover/feature/_attendance_/shared/presentation/widget/attendance_service_ui.dart';
import 'package:flutter/material.dart';

class AttendanceAbsenceTile extends StatelessWidget {
  const AttendanceAbsenceTile({
    super.key,
    required this.entry,
    required this.workerName,
  });

  final AttendanceAbsenceEntry entry;
  final String workerName;

  static String formatDay(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = attendanceServiceAccent(colors);
    final sameDay = entry.startDate.year == entry.endDate.year &&
        entry.startDate.month == entry.endDate.month &&
        entry.startDate.day == entry.endDate.day;
    final range = sameDay
        ? formatDay(entry.startDate)
        : '${formatDay(entry.startDate)} — ${formatDay(entry.endDate)}';

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
                child: Icon(AppIcons.eventBusy.icon, color: accent.icon, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      workerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyle.base(15, color: colors.textColor, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${entry.kind.labelRu} · $range',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyle.base(12, color: colors.subTextColor, fontWeight: FontWeight.w600),
                    ),
                    if (entry.note != null && entry.note!.trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        entry.note!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyle.base(12, color: colors.subTextColor),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
