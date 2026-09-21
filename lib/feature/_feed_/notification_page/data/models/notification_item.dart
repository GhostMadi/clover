import 'package:clover/feature/_feed_/notification_page/data/models/notification_actor.dart';
import 'package:clover/feature/_feed_/notification_page/data/models/notification_kind.dart';

class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.kind,
    required this.actors,
    required this.createdAt,
    this.postId,
    this.commentId,
    this.postPreviewUrl,
    this.commentPreview,
    this.isReply = false,
    this.isUnread = false,
    this.showFollowButton = false,
    this.isFollowingActor = false,
    this.bookingId,
    this.bookingServiceTitle,
    this.bookingStartsAt,
    this.bonusEarnAmount,
    this.bookingReminderMinutesBefore,
    this.bookingForHost,
    this.bookingHostId,
    this.workplaceId,
    this.attendanceDueKind,
    this.attendanceWorkplaceName,
    this.loginWhere,
    this.loginEventId,
    this.loginResolved,
    this.loginActions = const [],
  });

  final String id;
  final NotificationKind kind;
  final List<NotificationActor> actors;
  final DateTime createdAt;
  final String? postId;
  final String? commentId;
  final String? postPreviewUrl;
  final String? commentPreview;
  final bool isReply;
  final bool isUnread;
  final bool showFollowButton;
  final bool isFollowingActor;
  final String? bookingId;
  final String? bookingServiceTitle;
  final DateTime? bookingStartsAt;
  final int? bonusEarnAmount;
  final int? bookingReminderMinutesBefore;
  /// Payload `for_host` for [NotificationKind.bookingRescheduled].
  final bool? bookingForHost;
  /// Payload `host_id` for [NotificationKind.bookingAssignedStaff] open.
  final String? bookingHostId;
  /// Attendance payload workplace (invite / duty / correction / punch_due).
  final String? workplaceId;
  /// EN: clock_in | clock_out | auto_closed for punch_due.
  final String? attendanceDueKind;
  final String? attendanceWorkplaceName;
  /// Human-readable place for [NotificationKind.accountLogin].
  final String? loginWhere;
  final String? loginEventId;
  /// EN: confirmed | revoked | revoked_others
  final String? loginResolved;
  /// EN: confirm | revoke | change_password
  final List<String> loginActions;

  bool get showLoginActions =>
      kind == NotificationKind.accountLogin &&
      loginEventId != null &&
      loginEventId!.isNotEmpty &&
      (loginResolved == null || loginResolved!.isEmpty);

  NotificationItem copyWith({
    bool? isFollowingActor,
    bool? isUnread,
    NotificationKind? kind,
    String? loginResolved,
    bool clearLoginResolved = false,
  }) {
    return NotificationItem(
      id: id,
      kind: kind ?? this.kind,
      actors: actors,
      createdAt: createdAt,
      postId: postId,
      commentId: commentId,
      postPreviewUrl: postPreviewUrl,
      commentPreview: commentPreview,
      isReply: isReply,
      isUnread: isUnread ?? this.isUnread,
      showFollowButton: showFollowButton,
      isFollowingActor: isFollowingActor ?? this.isFollowingActor,
      bookingId: bookingId,
      bookingServiceTitle: bookingServiceTitle,
      bookingStartsAt: bookingStartsAt,
      bonusEarnAmount: bonusEarnAmount,
      bookingReminderMinutesBefore: bookingReminderMinutesBefore,
      bookingForHost: bookingForHost,
      bookingHostId: bookingHostId,
      workplaceId: workplaceId,
      attendanceDueKind: attendanceDueKind,
      attendanceWorkplaceName: attendanceWorkplaceName,
      loginWhere: loginWhere,
      loginEventId: loginEventId,
      loginResolved: clearLoginResolved ? null : (loginResolved ?? this.loginResolved),
      loginActions: loginActions,
    );
  }
}
