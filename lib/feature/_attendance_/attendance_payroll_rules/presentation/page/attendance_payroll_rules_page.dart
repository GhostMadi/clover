import 'package:auto_route/auto_route.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_snack_bar.dart';
import 'package:clover/core/shared/app_switch.dart';
import 'package:clover/feature/_attendance_/attendance_analytics/presentation/widget/attendance_analytics_ui.dart';
import 'package:clover/feature/_attendance_/attendance_payroll_rules/presentation/cubit/attendance_payroll_rules_cubit.dart';
import 'package:clover/feature/_attendance_/shared/data/attendance_error.dart';
import 'package:clover/feature/_attendance_/shared/data/attendance_outbox.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_payroll_models.dart';
import 'package:clover/feature/_attendance_/shared/presentation/widget/attendance_screen_shell.dart';
import 'package:clover/feature/_attendance_/shared/presentation/widget/attendance_service_ui.dart';
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
        final summary = state.summary;
        final rows = state.rows;

        return AttendanceScreenShell(
          title: 'Зарплата',
          showSave: true,
          isSaving: state.saving,
          onSaveTap: _save,
          body: ListView(
            padding: EdgeInsets.fromLTRB(16, 8, 16, AttendanceScreenShell.scrollBottomGap(context)),
            children: [
              Text(
                '${summary.periodLabel} · предварительный расчёт по текущим правилам и отметкам.',
                style: AppTextStyle.base(14, color: context.colors.subTextColor),
              ),
              if (state.loadingPreview) ...[
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  color: context.colors.primary,
                  backgroundColor: context.colors.surfaceMuted,
                ),
              ],
              const SizedBox(height: 16),
              _TeamSummaryCard(summary: summary),
              const SizedBox(height: 22),
              Text(
                'По работникам',
                style: AppTextStyle.base(17, color: context.colors.textColor, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'Оклад, списания и доплаты за месяц. Нажмите — детали и правка оклада.',
                style: AppTextStyle.base(13, color: context.colors.subTextColor),
              ),
              const SizedBox(height: 12),
              for (var i = 0; i < rows.length; i++) ...[
                _WorkerPayrollCard(payroll: rows[i], onTap: () => _showWorkerDetail(context, rows[i])),
                if (i < rows.length - 1) const SizedBox(height: 10),
              ],
              const SizedBox(height: 24),
              Text(
                'Правила начисления',
                style: AppTextStyle.base(17, color: context.colors.textColor, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'Что учитывать и по каким ставкам считать списания и доплаты.',
                style: AppTextStyle.base(13, color: context.colors.subTextColor),
              ),
              const SizedBox(height: 12),
              _RulesCard(
                children: [
                  _PayrollRuleBlock(
                    title: 'Опоздания уменьшают ЗП',
                    subtitle: 'Списание за каждую минуту опоздания.',
                    value: rules.lateDeductsPay,
                    onChanged: (v) => _cubit.setRules(rules.copyWith(lateDeductsPay: v)),
                    fieldLabel: '₸ за минуту',
                    fieldValue: rules.lateDeductPerMinute,
                    onFieldChanged: (v) => _cubit.setRules(rules.copyWith(lateDeductPerMinute: v)),
                  ),
                  Divider(height: 1, color: context.colors.divider),
                  _PayrollRuleBlock(
                    title: 'Переработка добавляет к ЗП',
                    subtitle: 'Доплата за каждый час сверх графика.',
                    value: rules.overtimeAddsPay,
                    onChanged: (v) => _cubit.setRules(rules.copyWith(overtimeAddsPay: v)),
                    fieldLabel: '₸ за час',
                    fieldValue: rules.overtimeBonusPerHour,
                    onFieldChanged: (v) => _cubit.setRules(rules.copyWith(overtimeBonusPerHour: v)),
                  ),
                  Divider(height: 1, color: context.colors.divider),
                  _PayrollRuleBlock(
                    title: 'Пропуски уменьшают ЗП',
                    subtitle: 'Фиксированное списание за день без отметки.',
                    value: rules.absenceDeductsPay,
                    onChanged: (v) => _cubit.setRules(rules.copyWith(absenceDeductsPay: v)),
                    fieldLabel: '₸ за день',
                    fieldValue: rules.absenceDeductPerDay,
                    onFieldChanged: (v) => _cubit.setRules(rules.copyWith(absenceDeductPerDay: v)),
                  ),
                  Divider(height: 1, color: context.colors.divider),
                  _PayrollRuleBlock(
                    title: 'Неполный день уменьшает ЗП',
                    subtitle: 'Процент от дневной ставки за частичную смену.',
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

  Future<void> _save() async {
    if (_cubit.state.saving) return;
    try {
      final result = await _cubit.save();
      if (!mounted) return;
      AppSnackBar.show(
        context,
        message: result == AttendancePersistResult.queued
            ? 'Сохранено локально, синхронизируется'
            : 'Правила сохранены',
        kind: AppSnackBarKind.success,
      );
      context.router.maybePop();
    } catch (e) {
      if (!mounted) return;
      final msg = e is AttendanceException ? e.userMessage : 'Не удалось сохранить';
      AppSnackBar.show(context, message: msg, kind: AppSnackBarKind.error);
    }
  }

  Future<void> _showWorkerDetail(BuildContext context, AttendanceWorkerPayroll payroll) {
    return AttendanceBottomSheet.show(
      context: context,
      title: payroll.displayName,
      content: _WorkerPayrollDetailSheet(payroll: payroll, cubit: _cubit),
    );
  }
}

class _TeamSummaryCard extends StatelessWidget {
  const _TeamSummaryCard({required this.summary});

  final AttendancePayrollTeamSummary summary;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = attendanceServiceAccent(colors);

    return AttendanceAnalyticsCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              AttendanceMetricIcon(icon: AppIcons.payments.icon, tint: accent.icon, bg: accent.soft),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      attendanceFormatMoney(summary.netPay),
                      style: AppTextStyle.base(28, color: colors.textColor, fontWeight: FontWeight.w800),
                    ),
                    Text(
                      'к выплате · ${summary.workerCount} чел.',
                      style: AppTextStyle.base(13, color: colors.subTextColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 14),
          _SummaryRow(label: 'Оклад (база)', value: attendanceFormatMoney(summary.totalBase)),
          const SizedBox(height: 8),
          _SummaryRow(
            label: 'Списания',
            value: '−${attendanceFormatMoney(summary.totalDeductions)}',
            valueColor: colors.functionalSoftYellowIcon,
          ),
          const SizedBox(height: 8),
          _SummaryRow(
            label: 'Доплаты',
            value: '+${attendanceFormatMoney(summary.totalBonuses)}',
            valueColor: accent.icon,
          ),
        ],
      ),
    );
  }
}

class _WorkerPayrollDetailSheet extends StatefulWidget {
  const _WorkerPayrollDetailSheet({required this.payroll, required this.cubit});

  final AttendanceWorkerPayroll payroll;
  final AttendancePayrollRulesCubit cubit;

  @override
  State<_WorkerPayrollDetailSheet> createState() => _WorkerPayrollDetailSheetState();
}

class _WorkerPayrollDetailSheetState extends State<_WorkerPayrollDetailSheet> {
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

  AttendanceWorkerPayroll get _currentPayroll {
    return widget.cubit.state.rows.firstWhere(
      (row) => row.workerId == widget.payroll.workerId,
      orElse: () => widget.payroll,
    );
  }

  Future<void> _saveSalary() async {
    final parsed = int.tryParse(_salaryController.text.trim());
    if (parsed == null || parsed <= 0) {
      AppSnackBar.show(context, message: 'Укажите оклад в ₸', kind: AppSnackBarKind.error);
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
        message: result == AttendancePersistResult.queued
            ? 'Сохранено локально, синхронизируется'
            : 'Оклад сохранён',
        kind: AppSnackBarKind.success,
      );
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      final msg = e is AttendanceException ? e.userMessage : 'Не удалось сохранить оклад';
      AppSnackBar.show(context, message: msg, kind: AppSnackBarKind.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = attendanceServiceAccent(colors);
    final yellow = attendanceYellowAccent(colors);
    final payroll = _currentPayroll;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(payroll.username, style: AppTextStyle.base(14, color: colors.subTextColor)),
        const SizedBox(height: 16),
        AttendanceField(
          controller: _salaryController,
          labelText: 'Оклад (база), ₸',
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        const SizedBox(height: 10),
        AttendancePrimaryButton(text: 'Сохранить оклад', isExpanded: true, onTap: _saveSalary),
        const SizedBox(height: 20),
        Text(
          'Оценка за ${widget.cubit.state.summary.periodLabel}',
          style: AppTextStyle.base(14, color: colors.textColor, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        if (payroll.lines.isEmpty)
          Text('Без корректировок за период.', style: AppTextStyle.base(14, color: colors.subTextColor))
        else
          for (final line in payroll.lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _PayrollLineTile(line: line),
            ),
        const SizedBox(height: 4),
        const Divider(height: 1),
        const SizedBox(height: 14),
        _DetailRow(label: 'Оклад (база)', value: attendanceFormatMoney(payroll.baseSalary)),
        if (payroll.totalDeductions > 0) ...[
          const SizedBox(height: 8),
          _DetailRow(
            label: 'Всего списано',
            value: '−${attendanceFormatMoney(payroll.totalDeductions)}',
            valueColor: yellow.icon,
          ),
        ],
        if (payroll.totalBonuses > 0) ...[
          const SizedBox(height: 8),
          _DetailRow(
            label: 'Всего доплата',
            value: '+${attendanceFormatMoney(payroll.totalBonuses)}',
            valueColor: accent.icon,
          ),
        ],
        const SizedBox(height: 12),
        _DetailRow(
          label: 'К выплате',
          value: attendanceFormatMoney(payroll.netPay),
          valueColor: accent.icon,
          bold: true,
        ),
      ],
    );
  }
}

class _PayrollLineTile extends StatelessWidget {
  const _PayrollLineTile({required this.line});

  final AttendancePayrollLineItem line;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = attendanceServiceAccent(colors);
    final yellow = attendanceYellowAccent(colors);
    final valueColor = switch (line.kind) {
      AttendancePayrollLineKind.bonus => accent.icon,
      AttendancePayrollLineKind.deduction => yellow.icon,
      AttendancePayrollLineKind.base => colors.textColor,
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceMuted,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.borderSoft),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.label,
                  style: AppTextStyle.base(14, color: colors.textColor, fontWeight: FontWeight.w600),
                ),
                if (line.detail != null) ...[
                  const SizedBox(height: 2),
                  Text(line.detail!, style: AppTextStyle.base(12, color: colors.subTextColor)),
                ],
              ],
            ),
          ),
          Text(
            attendanceFormatMoneySigned(line.amount, isBonus: line.kind == AttendancePayrollLineKind.bonus),
            style: AppTextStyle.base(14, color: valueColor, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        Expanded(
          child: Text(label, style: AppTextStyle.base(14, color: colors.subTextColor)),
        ),
        Text(
          value,
          style: AppTextStyle.base(14, color: valueColor ?? colors.textColor, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _WorkerPayrollCard extends StatelessWidget {
  const _WorkerPayrollCard({required this.payroll, required this.onTap});

  final AttendanceWorkerPayroll payroll;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = attendanceServiceAccent(colors);
    final yellow = attendanceYellowAccent(colors);

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.borderSoft),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          payroll.displayName,
                          style: AppTextStyle.base(16, color: colors.textColor, fontWeight: FontWeight.w700),
                        ),
                        Text(payroll.username, style: AppTextStyle.base(12, color: colors.subTextColor)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        attendanceFormatMoney(payroll.netPay),
                        style: AppTextStyle.base(16, color: accent.icon, fontWeight: FontWeight.w800),
                      ),
                      Text('к выплате', style: AppTextStyle.base(11, color: colors.subTextColor)),
                    ],
                  ),
                  const SizedBox(width: 4),
                  Icon(AppIcons.chevronRight.icon, size: 20, color: colors.subTextColor),
                ],
              ),
              const SizedBox(height: 12),
              _DetailRow(label: 'Оклад', value: attendanceFormatMoney(payroll.baseSalary)),
              for (final line in payroll.lines) ...[
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(line.label, style: AppTextStyle.base(13, color: colors.subTextColor)),
                          if (line.detail != null)
                            Text(
                              line.detail!,
                              style: AppTextStyle.base(
                                11,
                                color: colors.subTextColor.withValues(alpha: 0.85),
                              ),
                            ),
                        ],
                      ),
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
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value, this.valueColor, this.bold = false});

  final String label;
  final String value;
  final Color? valueColor;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTextStyle.base(
              bold ? 15 : 14,
              color: bold ? colors.textColor : colors.subTextColor,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: AppTextStyle.base(
            bold ? 16 : 14,
            color: valueColor ?? colors.textColor,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _RulesCard extends StatelessWidget {
  const _RulesCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.colors.borderSoft),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
    );
  }
}

class _PayrollRuleBlock extends StatefulWidget {
  const _PayrollRuleBlock({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.fieldLabel,
    required this.fieldValue,
    required this.onFieldChanged,
    this.maxValue,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String fieldLabel;
  final int fieldValue;
  final ValueChanged<int> onFieldChanged;
  final int? maxValue;

  @override
  State<_PayrollRuleBlock> createState() => _PayrollRuleBlockState();
}

class _PayrollRuleBlockState extends State<_PayrollRuleBlock> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '${widget.fieldValue}');
  }

  @override
  void didUpdateWidget(covariant _PayrollRuleBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fieldValue != widget.fieldValue && _controller.text != '${widget.fieldValue}') {
      _controller.text = '${widget.fieldValue}';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: AppTextStyle.base(15, color: colors.textColor, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.subtitle,
                      style: AppTextStyle.base(13, color: colors.subTextColor, height: 1.35),
                    ),
                  ],
                ),
              ),
              AppSwitch(value: widget.value, service: kAttendanceService, onChanged: widget.onChanged),
            ],
          ),
          if (widget.value) ...[
            const SizedBox(height: 12),
            AttendanceField(
              controller: _controller,
              labelText: widget.fieldLabel,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (raw) {
                final parsed = int.tryParse(raw.trim());
                if (parsed == null) return;
                final capped = widget.maxValue != null ? parsed.clamp(0, widget.maxValue!) : parsed;
                widget.onFieldChanged(capped);
              },
            ),
          ],
        ],
      ),
    );
  }
}
