import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_outlined_button.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_worker.dart';
import 'package:clover/feature/_attendance_/shared/presentation/widget/attendance_service_ui.dart';
import 'package:flutter/material.dart';

enum AttendanceWorkerSheetAction { open, archive, reinvite, openChat }

abstract final class AttendanceWorkersSheets {
  static String usernameLine(AttendanceWorkerListItem worker) {
    final raw = worker.username.trim();
    if (raw.isEmpty) return 'Аккаунт Clover';
    return raw.startsWith('@') ? raw : '@$raw';
  }

  static Future<AttendanceWorkerSheetAction?> showActive(
    BuildContext context,
    AttendanceWorkerListItem worker,
  ) {
    final subtitle = worker.isTagInactive
        ? '${usernameLine(worker)} · нет тега работника'
        : usernameLine(worker);
    return _show(
      context,
      title: worker.displayName,
      subtitle: subtitle,
      primary: 'Открыть',
      primaryAction: AttendanceWorkerSheetAction.open,
      secondary: 'В архив',
      secondaryAction: AttendanceWorkerSheetAction.archive,
    );
  }

  static Future<AttendanceWorkerSheetAction?> showPending(
    BuildContext context,
    AttendanceWorkerListItem worker,
  ) {
    return _show(
      context,
      title: worker.displayName,
      subtitle: '${usernameLine(worker)} · ждёт ответа в чате',
      primary: 'Открыть чат',
      primaryAction: AttendanceWorkerSheetAction.openChat,
      secondary: 'Закрыть',
      secondaryAction: null,
    );
  }

  static Future<AttendanceWorkerSheetAction?> showArchived(
    BuildContext context,
    AttendanceWorkerListItem worker,
  ) {
    return _show(
      context,
      title: worker.displayName,
      subtitle: '${usernameLine(worker)} · не в сменах',
      primary: 'Пригласить снова',
      primaryAction: AttendanceWorkerSheetAction.reinvite,
      secondary: 'Открыть',
      secondaryAction: AttendanceWorkerSheetAction.open,
    );
  }

  static Future<AttendanceWorkerSheetAction?> _show(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String primary,
    required AttendanceWorkerSheetAction primaryAction,
    required String secondary,
    required AttendanceWorkerSheetAction? secondaryAction,
  }) {
    return AttendanceBottomSheet.show<AttendanceWorkerSheetAction>(
      context: context,
      title: title,
      upperCaseTitle: false,
      showCloseButton: true,
      contentBottomSpacing: 8,
      content: Builder(
        builder: (sheetContext) {
          final colors = sheetContext.colors;
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                subtitle,
                style: AppTextStyle.base(14, color: colors.subTextColor, height: 1.35),
              ),
              const SizedBox(height: 16),
              AttendancePrimaryButton(
                text: primary,
                isExpanded: true,
                height: 48,
                onTap: () => Navigator.of(sheetContext).pop(primaryAction),
              ),
              const SizedBox(height: 8),
              AppOutlinedButton(
                text: secondary,
                isExpanded: true,
                height: 48,
                service: kAttendanceService,
                onTap: () {
                  if (secondaryAction == null) {
                    Navigator.of(sheetContext).pop();
                  } else {
                    Navigator.of(sheetContext).pop(secondaryAction);
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
