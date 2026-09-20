import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/feature/_attendance_/shared/presentation/widget/attendance_service_ui.dart';
import 'package:flutter/material.dart';

class AttendanceOvertimeSuggestionCard extends StatelessWidget {
  const AttendanceOvertimeSuggestionCard({
    super.key,
    required this.hours,
    required this.onCreateRequest,
  });

  final int hours;
  final VoidCallback onCreateRequest;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final yellow = attendanceYellowAccent(colors);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: yellow.icon.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(AppIcons.accessTime.icon, color: yellow.icon, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Уход позже графика · ~$hours ч',
                  style: AppTextStyle.base(15, color: colors.textColor, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AttendancePrimaryButton(
            text: 'Создать заявку',
            height: 44,
            isExpanded: true,
            onTap: onCreateRequest,
          ),
        ],
      ),
    );
  }
}
