import 'package:clover/feature/_post_/post_comment/data/models/comment_item.dart';
import 'package:clover/feature/_post_/post_comment/data/models/comment_model.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class PostCommentRepository {
  Future<List<CommentItem>> listRootComments({
    required String postId,
    int limit = 24,
    int offset = 0,
  });

  Future<List<CommentItem>> listReplies({
    required String postId,
    required String parentCommentId,
    int limit = 50,
    int offset = 0,
  });

  Future<CommentItem> createComment({
    required String postId,
    required String text,
    String? parentCommentId,
  });

  Future<String?> setReaction({required String commentId, required String? kind});
}

@LazySingleton(as: PostCommentRepository)
class PostCommentRepositoryImpl implements PostCommentRepository {
  PostCommentRepositoryImpl(this._client);

  final SupabaseClient _client;

  static const _rootPageCap = 200;
  static const _repliesPageCap = 200;

  @override
  Future<List<CommentItem>> listRootComments({
    required String postId,
    int limit = 24,
    int offset = 0,
  }) async {
    final id = postId.trim();
    if (id.isEmpty) return const [];

    final res = await _client.rpc(
      'list_post_root_comments_enriched',
      params: <String, dynamic>{
        'p_post_id': id,
        'p_limit': limit.clamp(1, _rootPageCap),
        'p_offset': offset < 0 ? 0 : offset,
      },
    );

    return _parseEnrichedList(res);
  }

  @override
  Future<List<CommentItem>> listReplies({
    required String postId,
    required String parentCommentId,
    int limit = 50,
    int offset = 0,
  }) async {
    final pid = postId.trim();
    final parentId = parentCommentId.trim();
    if (pid.isEmpty || parentId.isEmpty) return const [];

    final res = await _client.rpc(
      'list_comment_replies_enriched',
      params: <String, dynamic>{
        'p_post_id': pid,
        'p_parent_comment_id': parentId,
        'p_limit': limit.clamp(1, _repliesPageCap),
        'p_offset': offset < 0 ? 0 : offset,
      },
    );

    return _parseEnrichedList(res);
  }

  @override
  Future<CommentItem> createComment({
    required String postId,
    required String text,
    String? parentCommentId,
  }) async {
    final pid = postId.trim();
    final body = text.trim();
    if (pid.isEmpty || body.isEmpty) throw ArgumentError('postId/text');

    final uid = _client.auth.currentUser?.id.trim();
    if (uid == null || uid.isEmpty) throw StateError('Not authenticated');

    final payload = <String, dynamic>{
      'post_id': pid,
      'user_id': uid,
      'text': body,
    };

    final parent = parentCommentId?.trim();
    if (parent != null && parent.isNotEmpty) {
      payload['parent_comment_id'] = parent;
    }

    final row = await _client.from('comments').insert(payload).select().single();
    final comment = CommentModel.fromJson(Map<String, dynamic>.from(row));

    final profile = await _client
        .from('profiles')
        .select('username, avatar_url')
        .eq('id', uid)
        .maybeSingle();

    String? username;
    String? avatarUrl;
    if (profile != null) {
      final map = Map<String, dynamic>.from(profile);
      username = (map['username'] as String?)?.trim();
      avatarUrl = (map['avatar_url'] as String?)?.trim();
    }

    return CommentItem(
      comment: comment,
      authorUsername: username,
      authorAvatarUrl: avatarUrl,
    );
  }

  @override
  Future<String?> setReaction({required String commentId, required String? kind}) async {
    final id = commentId.trim();
    if (id.isEmpty) throw ArgumentError('commentId');

    final normalized = kind?.trim();
    final payload = (normalized == null || normalized.isEmpty) ? null : normalized;
    if (payload != null && payload != 'like' && payload != 'dislike') {
      throw ArgumentError('kind');
    }

    final res = await _client.rpc(
      'set_comment_reaction',
      params: <String, dynamic>{'p_comment_id': id, 'p_kind': payload},
    );

    if (res is List && res.isNotEmpty) {
      final row = res.first;
      if (row is Map) {
        final k = row['kind'];
        if (k == null) return null;
        if (k is String) {
          final t = k.trim();
          return t.isEmpty ? null : t;
        }
      }
    }

    return payload;
  }

  List<CommentItem> _parseEnrichedList(dynamic res) {
    if (res is! List) return const [];

    final items = <CommentItem>[];
    for (final row in res) {
      if (row is! Map) continue;
      final item = _parseEnrichedRow(Map<String, dynamic>.from(row));
      if (item != null) items.add(item);
    }
    return items;
  }

  CommentItem? _parseEnrichedRow(Map<String, dynamic> row) {
    final commentRaw = row['comment'];
    if (commentRaw is! Map) return null;

    final commentMap = Map<String, dynamic>.from(commentRaw);
    String? authorUsername;
    String? authorAvatarUrl;

    final profilesRaw = commentMap.remove('profiles');
    if (profilesRaw is Map) {
      final pm = Map<String, dynamic>.from(profilesRaw);
      final u = (pm['username'] as String?)?.trim();
      final a = (pm['avatar_url'] as String?)?.trim();
      authorUsername = (u != null && u.isNotEmpty) ? u : null;
      authorAvatarUrl = (a != null && a.isNotEmpty) ? a : null;
    }

    final comment = CommentModel.fromJson(commentMap);
    if (comment.id.isEmpty) return null;

    String? myKind;
    final kindRaw = row['my_kind'];
    if (kindRaw is String) {
      final k = kindRaw.trim();
      if (k == 'like' || k == 'dislike') myKind = k;
    }

    return CommentItem(
      comment: comment,
      authorUsername: authorUsername,
      authorAvatarUrl: authorAvatarUrl,
      myKind: myKind,
    );
  }
}
