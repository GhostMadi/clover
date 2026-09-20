import 'package:auto_route/auto_route.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_snack_bar.dart';
import 'package:clover/feature/_attendance_/attendance_payroll_rules/presentation/cubit/attendance_payroll_rules_cubit.dart';
import 'package:clover/feature/_attendance_/attendance_payroll_rules/presentation/widget/attendance_payroll_rule_block.dart';
import 'package:clover/feature/_attendance_/attendance_payroll_rules/presentation/widget/attendance_payroll_summary_card.dart';
import 'package:clover/feature/_attendance_/attendance_payroll_rules/presentation/widget/attendance_payroll_worker_sheet.dart';
import 'package:clover/feature/_attendance_/attendance_payroll_rules/presentation/widget/attendance_payroll_worker_tile.dart';
import 'package:clover/feature/_attendance_/shared/data/attendance_error.dart';
import 'package:clover/feature/_attendance_/shared/data/attendance_outbox.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_payroll_models.dart';
import 'package:clover/feature/_attendance_/shared/presentation/widget/attendance_screen_shell.dart';
import 'package:clover/feature/_attendance_/shared/presentation/widget/attendance_service_ui.dart';
import 'package:clover/feature/_attendance_/shared/presentation/widget/attendance_settings_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

@RoutePage()
class AttendancePayrollRulesPage extends StatefulWidget {
  const AttendancePayrollRulesPage({super.key, required this.workplaceId});

  final String workplaceId;

  @override
  State<AttendancePayrollRulesPage> createState() => _AttendancePayrollRulesPageState();
}

class _AttendancePayrollRulesPageState extends State<AttendancePayrollRulesPage> {
  late final AttendancePayrollRulesCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = sl<AttendancePayrollRulesCubit>()..bind(widget.workplaceId);
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  Future<void> _save() async {
    if (_cubit.state.saving) return;
    try {
      final result = await _cubit.save();
      if (!mounted) return;
      AppSnackBar.show(
        context,
        message: result == AttendancePersistResult.queued ? 'Сохранено локально' : 'Сохранено',
        kind: AppSnackBarKind.success,
      );
      context.router.maybePop();
    } catch (e) {
      if (!mounted) return;
      final msg = e is AttendanceException ? e.userMessage : 'Не удалось сохранить';
      AppSnackBar.show(context, message: msg, kind: AppSnackBarKind.error);
    }
  }

  Future<void> _openWorker(AttendanceWorkerPayroll payroll) async {
    HapticFeedback.selectionClick();
    await AttendancePayrollWorkerSheet.show(context, payroll: payroll, cubit: _cubit);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AttendancePayrollRulesCubit, AttendancePayrollRulesState>(
      bloc: _cubit,
      builder: (context, state) {
        final workplace = state.workplace;
        if (workplace == null) {
          return AttendanceScreenShell(
            title: 'Зарплата',
            body: Center(
              child: Text(
                'Компания не найдена',
                style: AppTextStyle.base(15, color: context.colors.subTextColor),
              ),
            ),
          );
        }

        final rules = state.rules;
        final colors = context.colors;
        final accent = attendanceServiceAccent(colors);

        return AttendanceScreenShell(
          title: 'Зарплата',
          showSave: true,
          isSaving: state.saving,
          onSaveTap: _save,
          body: ListView(
            padding: EdgeInsets.fromLTRB(16, 0, 16, AttendanceScreenShell.scrollBottomGap(context)),
            children: [
              AttendancePayrollSummaryCard(summary: state.summary),
              if (state.loadingPreview) ...[
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  minHeight: 2,
                  color: accent.icon,
                  backgroundColor: accent.soft,
                ),
              ],
              const SizedBox(height: 20),
              Text(
                'Работники',
                style: AppTextStyle.base(14, color: colors.subTextColor, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              if (state.rows.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Нет работников для расчёта',
                    style: AppTextStyle.base(14, color: colors.subTextColor),
                  ),
                )
              else
                for (final row in state.rows) ...[
                  AttendancePayrollWorkerTile(
                    payroll: row,
                    onTap: () => _openWorker(row),
                  ),
                  const SizedBox(height: 8),
                ],
              const SizedBox(height: 12),
              Text(
                'Правила',
                style: AppTextStyle.base(14, color: colors.subTextColor, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              AttendanceSettingsSurface(
                children: [
                  AttendancePayrollRuleBlock(
                    title: 'Опоздания',
                    value: rules.lateDeductsPay,
                    onChanged: (v) => _cubit.setRules(rules.copyWith(lateDeductsPay: v)),
                    fieldLabel: '₸ / мин',
                    fieldValue: rules.lateDeductPerMinute,
                    onFieldChanged: (v) => _cubit.setRules(rules.copyWith(lateDeductPerMinute: v)),
                  ),
                  Divider(height: 1, color: colors.divider),
                  AttendancePayrollRuleBlock(
                    title: 'Переработка',
                    value: rules.overtimeAddsPay,
                    onChanged: (v) => _cubit.setRules(rules.copyWith(overtimeAddsPay: v)),
                    fieldLabel: '₸ / час',
                    fieldValue: rules.overtimeBonusPerHour,
                    onFieldChanged: (v) => _cubit.setRules(rules.copyWith(overtimeBonusPerHour: v)),
                  ),
                  Divider(height: 1, color: colors.divider),
                  AttendancePayrollRuleBlock(
                    title: 'Пропуски',
                    value: rules.absenceDeductsPay,
                    onChanged: (v) => _cubit.setRules(rules.copyWith(absenceDeductsPay: v)),
                    fieldLabel: '₸ / день',
                    fieldValue: rules.absenceDeductPerDay,
                    onFieldChanged: (v) => _cubit.setRules(rules.copyWith(absenceDeductPerDay: v)),
                  ),
                  Divider(height: 1, color: colors.divider),
                  AttendancePayrollRuleBlock(
                    title: 'Неполный день',
                    value: rules.partialDayDeductsPay,
                    onChanged: (v) => _cubit.setRules(rules.copyWith(partialDayDeductsPay: v)),
                    fieldLabel: '% от дня',
                    fieldValue: rules.partialDayDeductPercent,
                    onFieldChanged: (v) => _cubit.setRules(rules.copyWith(partialDayDeductPercent: v)),
                    maxValue: 100,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
