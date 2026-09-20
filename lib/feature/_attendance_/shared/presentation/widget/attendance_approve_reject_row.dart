import 'package:clover/core/shared/app_outlined_button.dart';
import 'package:clover/feature/_attendance_/shared/presentation/widget/attendance_service_ui.dart';
import 'package:flutter/material.dart';

/// Пара кнопок Утвердить / Отклонить.
class AttendanceApproveRejectRow extends StatelessWidget {
  const AttendanceApproveRejectRow({
    super.key,
    required this.onApprove,
    required this.onReject,
  });

  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AttendancePrimaryButton(
            text: 'Утвердить',
            height: 44,
            onTap: onApprove,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: AppOutlinedButton(
            text: 'Отклонить',
            height: 44,
            service: kAttendanceService,
            onTap: onReject,
          ),
        ),
      ],
    );
  }
}
