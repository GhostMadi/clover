import 'package:clover/core/resources/app_icons.dart';
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
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(color: accent.soft, shape: BoxShape.circle),
              child: Icon(AppIcons.groupOutlined.icon, size: 34, color: accent.icon),
            ),
            const SizedBox(height: 16),
            Text(
              'Пока никого нет',
              textAlign: TextAlign.center,
              style: AppTextStyle.base(18, color: context.colors.textColor, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Пригласите аккаунт Clover — заявка уйдёт в чат',
              textAlign: TextAlign.center,
              style: AppTextStyle.base(14, color: context.colors.subTextColor, height: 1.35),
            ),
            const SizedBox(height: 20),
            AttendancePrimaryButton(text: 'Добавить', isExpanded: true, onTap: onAdd),
          ],
        ),
      ),
    );
  }
}
