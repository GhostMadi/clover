import 'package:auto_route/auto_route.dart';
import 'package:clover/core/extension/context.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/router/app_router.gr.dart';
import 'package:clover/core/shared/app_snack_bar.dart';
import 'package:clover/feature/_attendance_/shared/data/attendance_context_store.dart';
import 'package:clover/feature/_attendance_/shared/data/attendance_error.dart';
import 'package:clover/feature/_attendance_/shared/data/attendance_remote_repository.dart';
import 'package:flutter/material.dart';

/// Открыть групповой чат компании (все активные сотрудники).
Future<void> openAttendanceCompanyChat(BuildContext context, String workplaceId) async {
  final store = sl<AttendanceContextStore>();
  store.clearUnreadChat();

  final snap = store.snapshot.value;
  final workplace = snap?.workplaceById(workplaceId);
  final title = workplace?.name.trim().isNotEmpty == true
      ? context.l10n.attendance_chat_title_named(workplace!.name)
      : context.l10n.attendance_hub_title;

  var convId = workplace?.groupConversationId?.trim() ?? '';

  if (store.isRemote) {
    try {
      final remote = sl<AttendanceRemoteRepository>();
      // Always ensure + sync members (owner + active), then open real chat.
      convId = await remote.openCompanyChat(workplaceId);
      store.patchWorkplaceGroupChat(workplaceId, convId);
    } catch (e) {
      if (!context.mounted) return;
      final msg = e is AttendanceException ? e.userMessage : context.l10n.attendance_chat_open_failed;
      AppSnackBar.show(context, message: msg, kind: AppSnackBarKind.error);
      return;
    }
  }

  if (!context.mounted) return;

  if (convId.isNotEmpty) {
    context.router.push(
      ChatRoute(
        chatId: convId,
        username: title,
        isGroup: true,
      ),
    );
    return;
  }

  // Mock / offline fallback: local cards screen.
  context.router.push(AttendanceCompanyChatRoute(workplaceId: workplaceId));
}

/// DM с человеком после invite — появляется во вкладке Chat.
void openAttendanceInviteDm(
  BuildContext context, {
  required AttendanceInviteDm dm,
}) {
  final chatId = dm.conversationId.trim();
  context.router.push(
    ChatRoute(
      chatId: chatId.isEmpty ? null : chatId,
      otherUserId: dm.otherUserId,
      username: dm.username,
    ),
  );
}
