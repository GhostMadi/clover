enum NotificationKind {
  followedYou,
  youFollowed,
  mutualFollow,
  like,
  dislike,
  comment,
  commentLike,
  commentDislike,
  bookingCreatedHost,
  bookingBookedClient,
  bookingVisitStarted,
  bookingVisitNeedsClose,
  bookingCancelledHost,
  bookingCancelledClient,
  bookingCompletedClient,
  bookingNoShowClient,
  bookingReminderClient,
  attendanceInvite,
  attendanceRulesAck,
  attendanceDuty,
  attendanceCorrection,
  accountLogin,
}

extension NotificationKindBookingX on NotificationKind {
  bool get isBookingHostInbox =>
      this == NotificationKind.bookingCreatedHost ||
      this == NotificationKind.bookingVisitStarted ||
      this == NotificationKind.bookingVisitNeedsClose ||
      this == NotificationKind.bookingCancelledHost;

  bool get isBookingClientInbox =>
      this == NotificationKind.bookingBookedClient ||
      this == NotificationKind.bookingReminderClient ||
      this == NotificationKind.bookingCancelledClient ||
      this == NotificationKind.bookingCompletedClient ||
      this == NotificationKind.bookingNoShowClient;
}
