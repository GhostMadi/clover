import 'package:clover/feature/_feed_/notification_page/data/models/notification_actor.dart';
import 'package:clover/feature/_feed_/notification_page/data/models/notification_item.dart';
import 'package:clover/feature/_feed_/notification_page/data/models/notification_kind.dart';
import 'package:clover/feature/_feed_/notification_page/data/models/notifications_feed_page.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class NotificationsRepository {
  Future<NotificationsFeedPage> listNotifications({
    int limit = 24,
    NotificationItem? cursorItem,
  });

  Future<void> markRead({List<String>? ids});

  Future<int> countUnread();

  Future<void> confirmAccountLogin(String loginEventId);

  Future<void> revokeAccountLogin(String loginEventId);
}

@LazySingleton(as: NotificationsRepository)
class NotificationsRepositoryImpl implements NotificationsRepository {
  NotificationsRepositoryImpl(this._client);

  final SupabaseClient _client;

  static const _pageSizeCap = 100;

  @override
  Future<NotificationsFeedPage> listNotifications({
    int limit = 24,
    NotificationItem? cursorItem,
  }) async {
    final safeLimit = limit.clamp(1, _pageSizeCap);

    final params = <String, dynamic>{'p_limit': safeLimit};
    if (cursorItem != null) {
      params['p_cursor_created_at'] = cursorItem.createdAt.toUtc().toIso8601String();
      params['p_cursor_id'] = cursorItem.id;
    }

    final res = await _client.rpc('list_notifications_enriched_cursor', params: params);
    final items = _parseRows(res);

    return NotificationsFeedPage(
      items: items,
      hasMore: items.length >= safeLimit,
    );
  }

  @override
  Future<void> markRead({List<String>? ids}) async {
    final params = <String, dynamic>{};
    if (ids != null && ids.isNotEmpty) {
      params['p_ids'] = ids;
    }
    await _client.rpc('mark_notifications_read', params: params);
  }

  @override
  Future<int> countUnread() async {
    final res = await _client.rpc('count_unread_notifications');
    if (res is int) return res;
    if (res is num) return res.toInt();
    return 0;
  }

  @override
  Future<void> confirmAccountLogin(String loginEventId) async {
    await _client.rpc('confirm_account_login', params: {'p_event_id': loginEventId});
  }

  @override
  Future<void> revokeAccountLogin(String loginEventId) async {
    await _client.rpc('revoke_account_login', params: {'p_event_id': loginEventId});
  }

  static List<NotificationItem> _parseRows(dynamic res) {
    if (res is! List) return const [];

    final items = <NotificationItem>[];
    for (final row in res) {
      final item = _parseRow(row);
      if (item != null) items.add(item);
    }
    return items;
  }

  static NotificationItem? _parseRow(dynamic row) {
    if (row is! Map) return null;
    final map = Map<String, dynamic>.from(row);

    final id = (map['id'] as String?)?.trim();
    if (id == null || id.isEmpty) return null;

    final kindRaw = (map['kind'] as String?)?.trim();
    if (kindRaw == null || kindRaw.isEmpty) return null;

    final actor = _parseActor(map['actor']);
    if (actor == null) return null;

    final payloadRaw = map['payload'];
    final payload = payloadRaw is Map ? Map<String, dynamic>.from(payloadRaw) : const <String, dynamic>{};

    final createdAt = _parseDateTime(map['created_at']);
    if (createdAt == null) return null;

    final readAt = _parseDateTime(map['read_at']);
    final previewUrl = (map['post_preview_url'] as String?)?.trim();
    final commentPreview = (payload['comment_preview'] as String?)?.trim();

    final isFollowingActor = map['is_following_actor'] == true;
    final kind = _kindFromApi(kindRaw, isFollowingActor: isFollowingActor);
    final isReply = kindRaw == 'comment_reply' || payload['is_reply'] == true;
    final isFollowKind = kindRaw == 'user_follow';

    final bookingId = (map['booking_id'] as String?)?.trim();
    final serviceTitle = (payload['service_title'] as String?)?.trim();
    final bookingStartsAt = _parseDateTime(payload['starts_at']);
    final bonusRaw = payload['bonus_earn_amount'];
    final bonusEarnAmount = bonusRaw is num ? bonusRaw.toInt() : int.tryParse('$bonusRaw');
    final reminderRaw = payload['minutes_before'];
    final reminderMinutes =
        reminderRaw is num ? reminderRaw.toInt() : int.tryParse('$reminderRaw');

    final loginWhere = _loginWhereFromPayload(payload);
    final loginEventId = (payload['login_event_id'] as String?)?.trim();
    final loginResolved = (payload['resolved'] as String?)?.trim();
    final actionsRaw = payload['actions'];
    final loginActions = <String>[];
    if (actionsRaw is List) {
      for (final a in actionsRaw) {
        final s = a?.toString().trim();
        if (s != null && s.isNotEmpty) loginActions.add(s);
      }
    }

    return NotificationItem(
      id: id,
      kind: kind,
      actors: [actor],
      createdAt: createdAt,
      postId: (map['post_id'] as String?)?.trim(),
      commentId: (map['comment_id'] as String?)?.trim(),
      postPreviewUrl: previewUrl != null && previewUrl.isNotEmpty ? previewUrl : null,
      commentPreview: commentPreview != null && commentPreview.isNotEmpty ? commentPreview : null,
      isReply: isReply,
      isUnread: readAt == null,
      showFollowButton: isFollowKind,
      isFollowingActor: isFollowingActor,
      bookingId: bookingId != null && bookingId.isNotEmpty ? bookingId : null,
      bookingServiceTitle: serviceTitle != null && serviceTitle.isNotEmpty ? serviceTitle : null,
      bookingStartsAt: bookingStartsAt,
      bonusEarnAmount: bonusEarnAmount != null && bonusEarnAmount > 0 ? bonusEarnAmount : null,
      bookingReminderMinutesBefore:
          reminderMinutes != null && reminderMinutes > 0 ? reminderMinutes : null,
      loginWhere: loginWhere,
      loginEventId: loginEventId != null && loginEventId.isNotEmpty ? loginEventId : null,
      loginResolved: loginResolved != null && loginResolved.isNotEmpty ? loginResolved : null,
      loginActions: loginActions,
    );
  }

  static String? _loginWhereFromPayload(Map<String, dynamic> payload) {
    final device = (payload['device_label'] as String?)?.trim();
    if (device != null && device.isNotEmpty) return device;
    final client = (payload['client'] as String?)?.trim();
    final platform = (payload['platform'] as String?)?.trim();
    if (client == 'web') return 'веб';
    if (platform == 'ios') return 'iOS';
    if (platform == 'android') return 'Android';
    if (client == 'mobile') return 'телефона';
    return null;
  }

  static NotificationActor? _parseActor(dynamic raw) {
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);

    final id = (map['id'] as String?)?.trim();
    if (id == null || id.isEmpty) return null;

    final username = (map['username'] as String?)?.trim();
    final avatarUrl = (map['avatar_url'] as String?)?.trim();

    return NotificationActor(
      id: id,
      username: username != null && username.isNotEmpty ? username : 'noName',
      avatarUrl: avatarUrl,
    );
  }

  static NotificationKind _kindFromApi(String kind, {required bool isFollowingActor}) {
    return switch (kind) {
      'post_like' => NotificationKind.like,
      'post_dislike' => NotificationKind.dislike,
      'post_comment' => NotificationKind.comment,
      'comment_reply' => NotificationKind.comment,
      'comment_like' => NotificationKind.commentLike,
      'comment_dislike' => NotificationKind.commentDislike,
      'user_follow' => isFollowingActor ? NotificationKind.mutualFollow : NotificationKind.followedYou,
      'booking_created_host' => NotificationKind.bookingCreatedHost,
      'booking_booked_client' => NotificationKind.bookingBookedClient,
      'booking_reminder_client' => NotificationKind.bookingReminderClient,
      'booking_visit_started' => NotificationKind.bookingVisitStarted,
      'booking_visit_needs_close' => NotificationKind.bookingVisitNeedsClose,
      'booking_cancelled_host' => NotificationKind.bookingCancelledHost,
      'booking_cancelled_client' => NotificationKind.bookingCancelledClient,
      'booking_completed_client' => NotificationKind.bookingCompletedClient,
      'booking_no_show_client' => NotificationKind.bookingNoShowClient,
      'attendance_invite' => NotificationKind.attendanceInvite,
      'attendance_rules_ack' => NotificationKind.attendanceRulesAck,
      'attendance_duty' => NotificationKind.attendanceDuty,
      'attendance_correction' => NotificationKind.attendanceCorrection,
      'account_login' => NotificationKind.accountLogin,
      _ => NotificationKind.comment,
    };
  }

  static DateTime? _parseDateTime(dynamic raw) {
    if (raw is DateTime) return raw.toLocal();
    if (raw is String && raw.isNotEmpty) {
      return DateTime.tryParse(raw)?.toLocal();
    }
    return null;
  }
}
