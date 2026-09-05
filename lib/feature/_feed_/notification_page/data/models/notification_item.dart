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

  NotificationItem copyWith({
    bool? isFollowingActor,
    bool? isUnread,
    NotificationKind? kind,
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
    );
  }
}
