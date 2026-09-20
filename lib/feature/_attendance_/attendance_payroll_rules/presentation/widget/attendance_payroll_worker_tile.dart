import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_payroll_models.dart';
import 'package:clover/feature/_attendance_/shared/presentation/widget/attendance_service_ui.dart';
import 'package:flutter/material.dart';

/// Компактная строка работника в зарплате.
class AttendancePayrollWorkerTile extends StatelessWidget {
  const AttendancePayrollWorkerTile({
    super.key,
    required this.payroll,
    required this.onTap,
  });

  final AttendanceWorkerPayroll payroll;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = attendanceServiceAccent(colors);
    final username = payroll.username.trim();
    final subtitle = username.isEmpty
        ? attendanceFormatMoney(payroll.baseSalary)
        : '${username.startsWith('@') ? username : '@$username'} · ${attendanceFormatMoney(payroll.baseSalary)}';

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        payroll.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyle.base(15, color: colors.textColor, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyle.base(12, color: colors.subTextColor, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                Text(
                  attendanceFormatMoney(payroll.netPay),
                  style: AppTextStyle.base(15, color: accent.icon, fontWeight: FontWeight.w800),
                ),
                const SizedBox(width: 4),
                Icon(AppIcons.chevronRight.icon, size: 20, color: colors.iconMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
