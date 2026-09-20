import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_payroll_models.dart';
import 'package:clover/feature/_attendance_/shared/presentation/widget/attendance_service_ui.dart';
import 'package:flutter/material.dart';

class AttendancePayrollSummaryCard extends StatelessWidget {
  const AttendancePayrollSummaryCard({super.key, required this.summary});

  final AttendancePayrollTeamSummary summary;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = attendanceServiceAccent(colors);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border.withValues(alpha: 0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: accent.soft, borderRadius: BorderRadius.circular(14)),
                alignment: Alignment.center,
                child: Icon(AppIcons.payments.icon, color: accent.icon, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      attendanceFormatMoney(summary.netPay),
                      style: AppTextStyle.base(22, color: colors.textColor, fontWeight: FontWeight.w800),
                    ),
                    Text(
                      '${summary.periodLabel} · ${summary.workerCount} чел.',
                      style: AppTextStyle.base(13, color: colors.subTextColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _Row(label: 'Оклад', value: attendanceFormatMoney(summary.totalBase)),
          const SizedBox(height: 6),
          _Row(
            label: 'Списания',
            value: '−${attendanceFormatMoney(summary.totalDeductions)}',
            valueColor: colors.functionalSoftYellowIcon,
          ),
          const SizedBox(height: 6),
          _Row(
            label: 'Доплаты',
            value: '+${attendanceFormatMoney(summary.totalBonuses)}',
            valueColor: accent.icon,
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        Expanded(child: Text(label, style: AppTextStyle.base(13, color: colors.subTextColor))),
        Text(
          value,
          style: AppTextStyle.base(13, color: valueColor ?? colors.textColor, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
