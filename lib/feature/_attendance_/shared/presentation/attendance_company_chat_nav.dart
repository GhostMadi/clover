import 'package:auto_route/auto_route.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/router/app_router.gr.dart';
import 'package:clover/feature/_attendance_/shared/data/attendance_context_store.dart';
import 'package:flutter/widgets.dart';

/// Открыть mock-чат компании (правила / ack), не общий inbox.
void openAttendanceCompanyChat(BuildContext context, String workplaceId) {
  sl<AttendanceContextStore>().clearUnreadChat();
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
