import 'package:auto_route/auto_route.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/router/app_router.gr.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_snapshot.dart';
import 'package:clover/feature/_attendance_/shared/presentation/attendance_company_chat_nav.dart';
import 'package:clover/feature/_attendance_/shared/presentation/widget/attendance_service_ui.dart';
import 'package:flutter/material.dart';
import 'package:clover/core/extension/context.dart';

/// Напоминание «Надо отметиться» на дашборде.
abstract final class AttendancePendingSheet {
  static Future<void> showIfNeeded(BuildContext context, AttendanceSnapshot snap) {
    final pending = snap.resolvePendingPunch();
    if (pending == null) return Future.value();

    final needsAck = snap.memberships.any((m) => m.needsAck);
    if (needsAck) {
      return _showAckRequired(context, snap);
    }

    return context.router.push(AttendancePendingRoute(workplaceId: pending.workplaceId));
  }

  static Future<void> _showAckRequired(BuildContext context, AttendanceSnapshot snap) {
    final m = snap.memberships.firstWhere((e) => e.needsAck);
    return AttendanceBottomSheet.show(
      context: context,
      title: context.l10n.attendance_pending_new_rules,
      content: Text(
        context.l10n.attendance_pending_accept(m.workplaceName, '${m.configVersion}'),
        style: AppTextStyle.base(15, color: context.colors.textColor),
      ),
      actions: [
        AttendancePrimaryButton(
          text: context.l10n.attendance_punch_open_chat,
          isExpanded: true,
          onTap: () {
            Navigator.of(context).pop();
            openAttendanceCompanyChat(context, m.workplaceId);
          },
        ),
      ],
    );
  }
}
