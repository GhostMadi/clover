import 'package:clover/feature/_post_/post_share/data/models/post_share_recipient.dart';
import 'package:clover/feature/_post_/post_share/data/models/post_share_result.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class PostShareRepository {
  Future<List<PostShareRecipient>> listFollowing({int limit = 500});

  Future<List<PostShareRecipient>> listFrequentRecipients({int limit = 10});

  Future<PostShareResult> sharePostToRecipients({
    required String postId,
    required List<String> recipientIds,
    String? message,
  });
}

@LazySingleton(as: PostShareRepository)
class PostShareRepositoryImpl implements PostShareRepository {
  PostShareRepositoryImpl(this._client);

  final SupabaseClient _client;

  String? get _currentUserId => _client.auth.currentUser?.id.trim();

  @override
  Future<List<PostShareRecipient>> listFollowing({int limit = 500}) async {
    final uid = _currentUserId;
    if (uid == null || uid.isEmpty) return const [];

    final res = await _client.rpc(
      'list_profile_following',
      params: {
        'p_profile_id': uid,
        'p_limit': limit.clamp(1, 500),
        'p_offset': 0,
      },
    );

    return _parseProfileRows(res);
  }

  @override
  Future<List<PostShareRecipient>> listFrequentRecipients({int limit = 10}) async {
    final uid = _currentUserId;
    if (uid == null || uid.isEmpty) return const [];

    try {
      final res = await _client.rpc(
        'list_post_share_frequent_recipients',
        params: {'p_limit': limit.clamp(1, 50)},
      );
      return _parseProfileRows(res, withShareCount: true);
    } catch (_) {
      return const [];
    }
  }

  List<PostShareRecipient> _parseProfileRows(dynamic res, {bool withShareCount = false}) {
    if (res is! List) return const [];

    final items = <PostShareRecipient>[];
    for (final raw in res) {
      if (raw is! Map) continue;
      final map = Map<String, dynamic>.from(raw);
      final profileId = map['profile_id']?.toString().trim();
      if (profileId == null || profileId.isEmpty) continue;

      items.add(
        PostShareRecipient(
          profileId: profileId,
          username: map['username']?.toString(),
          avatarUrl: map['avatar_url']?.toString(),
          shareCount: withShareCount ? ((map['share_count'] as num?)?.toInt() ?? 0) : 0,
        ),
      );
    }
    return items;
  }

  @override
  Future<PostShareResult> sharePostToRecipients({
    required String postId,
    required List<String> recipientIds,
    String? message,
  }) async {
    final uid = _currentUserId;
    if (uid == null || uid.isEmpty) {
      throw const PostShareException('Войдите в аккаунт');
    }

    final post = postId.trim();
    if (post.isEmpty) throw const PostShareException('Некорректный пост');

    final recipients = recipientIds.map((id) => id.trim()).where((id) => id.isNotEmpty).toSet().toList(growable: false);
    if (recipients.isEmpty) {
      throw const PostShareException('Выберите получателей');
    }

    final caption = message?.trim();

    try {
      final res = await _client.rpc(
        'share_post_to_recipients',
        params: {
          'p_post_id': post,
          'p_recipient_ids': recipients,
          if (caption != null && caption.isNotEmpty) 'p_message': caption,
        },
      );

      if (res is! Map) {
        throw const PostShareException('Не удалось отправить пост');
      }

      final result = PostShareResult.fromJson(Map<String, dynamic>.from(res));
      if (result.sharedCount <= 0) {
        throw const PostShareException('Не удалось отправить пост');
      }

      return result;
    } on PostgrestException catch (e) {
      throw PostShareException(_mapShareError(e));
    }
  }

  String _mapShareError(PostgrestException error) {
    final message = error.message.toLowerCase();
    if (message.contains('post_not_shareable')) return 'Этот пост нельзя отправить';
    if (message.contains('recipients_required')) return 'Выберите получателей';
    if (message.contains('share_failed')) return 'Не удалось отправить ни одному получателю';
    if (message.contains('not_authenticated')) return 'Войдите в аккаунт';
    return error.message.trim().isEmpty ? 'Не удалось отправить пост' : error.message;
  }
}

class PostShareException implements Exception {
  const PostShareException(this.message);

  final String message;

  @override
  String toString() => message;
}
