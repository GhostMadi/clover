import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_snack_bar.dart';
import 'package:clover/feature/_attendance_/attendance_payroll_rules/presentation/cubit/attendance_payroll_rules_cubit.dart';
import 'package:clover/feature/_attendance_/shared/data/attendance_error.dart';
import 'package:clover/feature/_attendance_/shared/data/attendance_outbox.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_payroll_models.dart';
import 'package:clover/feature/_attendance_/shared/presentation/widget/attendance_service_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:clover/core/extension/context.dart';

abstract final class AttendancePayrollWorkerSheet {
  static Future<void> show(
    BuildContext context, {
    required AttendanceWorkerPayroll payroll,
    required AttendancePayrollRulesCubit cubit,
  }) {
    return AttendanceBottomSheet.show(
      context: context,
      title: payroll.displayName,
      upperCaseTitle: false,
      showCloseButton: true,
      contentBottomSpacing: 8,
      content: _Body(payroll: payroll, cubit: cubit),
    );
  }
}

class _Body extends StatefulWidget {
  const _Body({required this.payroll, required this.cubit});

  final AttendanceWorkerPayroll payroll;
  final AttendancePayrollRulesCubit cubit;

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  late final TextEditingController _salaryController;

  @override
  void initState() {
    super.initState();
    _salaryController = TextEditingController(text: '${widget.payroll.baseSalary}');
  }

  @override
  void dispose() {
    _salaryController.dispose();
    super.dispose();
  }

  AttendanceWorkerPayroll get _current {
    return widget.cubit.state.rows.firstWhere(
      (row) => row.workerId == widget.payroll.workerId,
      orElse: () => widget.payroll,
    );
  }

  Future<void> _saveSalary() async {
    final parsed = int.tryParse(_salaryController.text.trim());
    if (parsed == null || parsed <= 0) {
      AppSnackBar.show(context, message: context.l10n.attendance_payroll_enter_salary, kind: AppSnackBarKind.error);
      return;
    }
    try {
      final result = await widget.cubit.updateWorkerBaseSalary(
        workerId: widget.payroll.workerId,
        baseSalary: parsed,
      );
      if (!mounted) return;
      AppSnackBar.show(
        context,
        message: result == AttendancePersistResult.queued ? context.l10n.attendance_saved_locally : context.l10n.attendance_payroll_salary_saved,
        kind: AppSnackBarKind.success,
      );
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      final msg = e is AttendanceException ? e.userMessage : context.l10n.attendance_payroll_salary_save_failed;
      AppSnackBar.show(context, message: msg, kind: AppSnackBarKind.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = attendanceServiceAccent(colors);
    final yellow = attendanceYellowAccent(colors);
    final payroll = _current;
    final username = payroll.username.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (username.isNotEmpty)
          Text(
            username.startsWith('@') ? username : '@$username',
            style: AppTextStyle.base(14, color: colors.subTextColor),
          ),
        const SizedBox(height: 12),
        AttendanceField(
          controller: _salaryController,
          labelText: context.l10n.attendance_payroll_salary_label,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        const SizedBox(height: 10),
        AttendancePrimaryButton(text: context.l10n.attendance_payroll_save_salary, isExpanded: true, height: 48, onTap: _saveSalary),
        const SizedBox(height: 16),
        Text(
          context.l10n.attendance_payroll_for_period(widget.cubit.state.summary.periodLabel),
          style: AppTextStyle.base(14, color: colors.subTextColor, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        if (payroll.lines.isEmpty)
          Text(context.l10n.attendance_payroll_no_adjustments, style: AppTextStyle.base(14, color: colors.subTextColor))
        else
          for (final line in payroll.lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(line.label, style: AppTextStyle.base(13, color: colors.subTextColor)),
                  ),
                  Text(
                    attendanceFormatMoneySigned(
                      line.amount,
                      isBonus: line.kind == AttendancePayrollLineKind.bonus,
                    ),
                    style: AppTextStyle.base(
                      13,
                      color: line.kind == AttendancePayrollLineKind.bonus ? accent.icon : yellow.icon,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                context.l10n.attendance_analytics_payout,
                style: AppTextStyle.base(15, color: colors.textColor, fontWeight: FontWeight.w700),
              ),
            ),
            Text(
              attendanceFormatMoney(payroll.netPay),
              style: AppTextStyle.base(16, color: accent.icon, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ],
    );
  }
}
