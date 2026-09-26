import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/feature/_attendance_/shared/presentation/widget/attendance_service_ui.dart';
import 'package:flutter/material.dart';
import 'package:clover/core/extension/context.dart';

/// Компактный блок «сегодня дежурит».
class AttendanceDutyTodayCard extends StatelessWidget {
  const AttendanceDutyTodayCard({
    super.key,
    required this.names,
    required this.strictMode,
  });

  final List<String> names;
  final bool strictMode;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = attendanceServiceAccent(colors);

    return Container(
      padding: EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border.withValues(alpha: 0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.common_today,
            style: AppTextStyle.base(13, color: colors.subTextColor, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 6),
          Text(
            names.isEmpty ? context.l10n.attendance_duty_none : names.join(', '),
            style: AppTextStyle.base(17, color: colors.textColor, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 6),
          Text(
            strictMode ? context.l10n.attendance_duty_punch_only_duty : context.l10n.attendance_duty_team_hint,
            style: AppTextStyle.base(13, color: accent.icon, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
