import 'package:auto_route/auto_route.dart';
import 'package:clover/core/deep_link/app_deep_link_intent.dart';
import 'package:clover/core/deep_link/app_deep_link_navigator.dart';
import 'package:clover/feature/_feed_/notification_page/data/models/notification_item.dart';
import 'package:clover/feature/_feed_/notification_page/data/models/notification_kind.dart';
import 'package:injectable/injectable.dart';

/// Maps notification EN `kind` + ids → [AppDeepLinkIntent] (FCM / bell / snack).
@lazySingleton
class NotificationOpenRouter {
  NotificationOpenRouter(this._navigator);

  final AppDeepLinkNavigator _navigator;

  Future<void> open(
    StackRouter router, {
    required String kind,
    required Map<String, dynamic> data,
  }) async {
    final intent = intentFor(kind: kind, data: data);
    if (intent == null) return;
    await _navigator.navigate(router, intent);
  }

  Future<void> openItem(StackRouter router, NotificationItem item) async {
    final intent = intentForItem(item);
    if (intent == null) return;
    await _navigator.navigate(router, intent);
  }

  AppDeepLinkIntent? intentForItem(NotificationItem item) {
    final postId = item.postId?.trim();
    if (postId != null && postId.isNotEmpty) {
      return AppDeepLinkPostIntent(postId);
    }

    if (item.kind == NotificationKind.bookingAssignedStaff) {
      return AppDeepLinkStaffCalendarIntent(hostId: item.bookingHostId);
    }

    if (item.kind == NotificationKind.bookingRescheduled) {
      final bookingId = item.bookingId?.trim();
      if (item.bookingForHost == true) {
        return AppDeepLinkHostBookingsIntent(bookingId: bookingId);
      }
      return AppDeepLinkMyBookingsIntent(bookingId: bookingId);
    }

    final bookingId = item.bookingId?.trim();
    if (bookingId != null && bookingId.isNotEmpty) {
      return item.kind.isBookingHostInbox
          ? AppDeepLinkHostBookingsIntent(bookingId: bookingId)
          : AppDeepLinkMyBookingsIntent(bookingId: bookingId);
    }

    if (item.kind.isBookingHostInbox) {
      return const AppDeepLinkHostBookingsIntent();
    }
    if (item.kind.isBookingClientInbox) {
      return const AppDeepLinkMyBookingsIntent();
    }

    if (item.kind == NotificationKind.followedYou ||
        item.kind == NotificationKind.mutualFollow ||
        item.kind == NotificationKind.youFollowed ||
        item.showFollowButton) {
      final userId = item.actors.isNotEmpty ? item.actors.first.id.trim() : '';
      if (userId.isNotEmpty) return AppDeepLinkProfileIntent(userId);
    }

    if (item.kind == NotificationKind.attendanceInvite ||
        item.kind == NotificationKind.attendanceRulesAck ||
        item.kind == NotificationKind.attendanceDuty ||
        item.kind == NotificationKind.attendanceCorrection ||
        item.kind == NotificationKind.attendancePunchDue) {
      return AppDeepLinkAttendanceIntent(workplaceId: item.workplaceId);
    }

    // account_login — CTA only
    return null;
  }

  AppDeepLinkIntent? intentFor({
    required String kind,
    required Map<String, dynamic> data,
  }) {
    final k = kind.trim();
    if (k.isEmpty) return null;

    String? str(String key) {
      final v = data[key];
      if (v == null) return null;
      final s = v.toString().trim();
      return s.isEmpty ? null : s;
    }

    switch (k) {
      case 'post_like':
      case 'post_dislike':
      case 'post_comment':
      case 'comment_reply':
      case 'comment_like':
      case 'comment_dislike':
        final postId = str('post_id');
        if (postId == null) return null;
        return AppDeepLinkPostIntent(postId);

      case 'user_follow':
        final actorId = str('actor_id') ?? str('user_id');
        if (actorId == null) return null;
        return AppDeepLinkProfileIntent(actorId);

      case 'booking_assigned_staff':
        return AppDeepLinkStaffCalendarIntent(hostId: str('host_id'));

      case 'booking_created_host':
      case 'booking_visit_started':
      case 'booking_visit_needs_close':
      case 'booking_cancelled_host':
        final bookingId = str('booking_id');
        return AppDeepLinkHostBookingsIntent(bookingId: bookingId);

      case 'booking_booked_client':
      case 'booking_reminder_client':
      case 'booking_cancelled_client':
      case 'booking_completed_client':
      case 'booking_no_show_client':
        final bookingId = str('booking_id');
        return AppDeepLinkMyBookingsIntent(bookingId: bookingId);

      case 'booking_rescheduled':
        final bookingId = str('booking_id');
        final forHost = data['for_host'];
        final isHost = forHost == true || forHost == 'true';
        if (isHost) {
          return AppDeepLinkHostBookingsIntent(bookingId: bookingId);
        }
        return AppDeepLinkMyBookingsIntent(bookingId: bookingId);

      case 'attendance_invite':
      case 'attendance_rules_ack':
      case 'attendance_duty':
      case 'attendance_correction':
      case 'attendance_punch_due':
        return AppDeepLinkAttendanceIntent(workplaceId: str('workplace_id'));

      case 'chat_message':
        final conversationId = str('conversation_id');
        if (conversationId == null) return null;
        final peer = str('peer_username') ?? 'Чат';
        final isGroup = str('is_group') == 'true';
        return AppDeepLinkChatIntent(
          chatId: conversationId,
          username: peer,
          isGroup: isGroup,
        );

      case 'account_login':
        return null;

      default:
        return const AppDeepLinkNotificationsIntent();
    }
  }
}
