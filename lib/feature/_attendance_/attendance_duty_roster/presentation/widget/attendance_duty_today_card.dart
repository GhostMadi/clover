import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/feature/_attendance_/shared/presentation/widget/attendance_service_ui.dart';
import 'package:flutter/material.dart';

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
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border.withValues(alpha: 0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Сегодня',
            style: AppTextStyle.base(13, color: colors.subTextColor, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            names.isEmpty ? 'Нет дежурного' : names.join(', '),
            style: AppTextStyle.base(17, color: colors.textColor, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            strictMode ? 'Отметка только у дежурного' : 'Подсказка для команды',
            style: AppTextStyle.base(13, color: accent.icon, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
