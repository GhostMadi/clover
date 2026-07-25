import 'package:clover/feature/notification_page/data/models/notification_actor.dart';
import 'package:clover/feature/notification_page/data/models/notification_item.dart';
import 'package:clover/feature/notification_page/data/models/notification_kind.dart';
import 'package:clover/feature/notification_page/data/models/notifications_feed_page.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class NotificationsRepository {
  Future<NotificationsFeedPage> listNotifications({
    int limit = 24,
    NotificationItem? cursorItem,
  });

  Future<void> markRead({List<String>? ids});
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

    final kind = _kindFromApi(kindRaw);
    final isReply = kindRaw == 'comment_reply' || payload['is_reply'] == true;

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
    );
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

  static NotificationKind _kindFromApi(String kind) {
    return switch (kind) {
      'post_like' => NotificationKind.like,
      'post_dislike' => NotificationKind.dislike,
      'post_comment' => NotificationKind.comment,
      'comment_reply' => NotificationKind.comment,
      'comment_like' => NotificationKind.commentLike,
      'comment_dislike' => NotificationKind.commentDislike,
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
