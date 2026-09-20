import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_switch.dart';
import 'package:clover/feature/_attendance_/shared/presentation/widget/attendance_service_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Правило начисления: switch + поле ставки.
class AttendancePayrollRuleBlock extends StatefulWidget {
  const AttendancePayrollRuleBlock({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    required this.fieldLabel,
    required this.fieldValue,
    required this.onFieldChanged,
    this.maxValue,
  });

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String fieldLabel;
  final int fieldValue;
  final ValueChanged<int> onFieldChanged;
  final int? maxValue;

  @override
  State<AttendancePayrollRuleBlock> createState() => _AttendancePayrollRuleBlockState();
}

class _AttendancePayrollRuleBlockState extends State<AttendancePayrollRuleBlock> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '${widget.fieldValue}');
  }

  @override
  void didUpdateWidget(covariant AttendancePayrollRuleBlock oldWidget) {
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
            children: [
              Expanded(
                child: Text(
                  widget.title,
                  style: AppTextStyle.base(15, color: colors.textColor, fontWeight: FontWeight.w700),
                ),
              ),
              AppSwitch(value: widget.value, service: kAttendanceService, onChanged: widget.onChanged),
            ],
          ),
          if (widget.value) ...[
            const SizedBox(height: 10),
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
