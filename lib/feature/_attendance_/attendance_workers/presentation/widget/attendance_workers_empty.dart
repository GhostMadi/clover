import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/extension/context.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/feature/_attendance_/shared/presentation/widget/attendance_service_ui.dart';
import 'package:flutter/material.dart';

class AttendanceWorkersEmpty extends StatelessWidget {
  const AttendanceWorkersEmpty({super.key, required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final accent = attendanceServiceAccent(context.colors);

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(color: accent.soft, shape: BoxShape.circle),
              child: Icon(AppIcons.groupOutlined.icon, size: 34, color: accent.icon),
            ),
            SizedBox(height: 16),
            Text(
              context.l10n.attendance_workers_empty_title,
              textAlign: TextAlign.center,
              style: AppTextStyle.base(18, color: context.colors.textColor, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 8),
            Text(
              context.l10n.attendance_workers_empty_subtitle,
              textAlign: TextAlign.center,
              style: AppTextStyle.base(14, color: context.colors.subTextColor, height: 1.35),
            ),
            SizedBox(height: 20),
            AttendancePrimaryButton(text: context.l10n.common_add, isExpanded: true, onTap: onAdd),
          ],
        ),
      ),
    );
  }
}
