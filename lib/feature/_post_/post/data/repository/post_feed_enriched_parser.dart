import 'package:clover/feature/post/data/models/post_feed_item.dart';
import 'package:clover/feature/post/data/models/post_marker_summary.dart';
import 'package:clover/feature/post/data/models/post_model.dart';
import 'package:clover/feature/post/data/models/post_profile_filter_value.dart';

typedef PostFeedItemCache = void Function(PostFeedItem item);

/// Парсинг строк enriched-RPC (`post`, `author`, `my_reaction`, …).
abstract final class PostFeedEnrichedParser {
  static List<PostFeedItem> parse(
    dynamic res, {
    bool? onlyWithMarker,
    PostFeedItemCache? onItemParsed,
  }) {
    if (res is! List) return const [];

    final items = <PostFeedItem>[];
    for (final row in res) {
      if (row is! Map) continue;
      final item = _parseRow(Map<String, dynamic>.from(row), onlyWithMarker: onlyWithMarker);
      if (item == null) continue;
      onItemParsed?.call(item);
      items.add(item);
    }
    return items;
  }

  static PostFeedItem? _parseRow(
    Map<String, dynamic> row, {
    bool? onlyWithMarker,
  }) {
    final postRaw = row['post'];
    if (postRaw is! Map) return null;

    final postMap = Map<String, dynamic>.from(postRaw);
    postMap.remove('profile_filters');
    postMap.remove('tags');
    final profileFilters = PostProfileFilterValue.listFromJson(postRaw['profile_filters']);
    final marker = PostMarkerSummary.tryFromJson(postMap['marker']);
    final post = PostModel.fromJson({
      ...postMap,
      'tags': postRaw['tags'],
    });

    if (onlyWithMarker != null) {
      if (onlyWithMarker ? !post.hasMarker : post.hasMarker) return null;
    }

    String? authorUsername;
    String? authorAvatarUrl;
    final authorRaw = row['author'];
    if (authorRaw is Map) {
      final am = Map<String, dynamic>.from(authorRaw);
      final u = (am['username'] as String?)?.trim();
      final a = (am['avatar_url'] as String?)?.trim();
      authorUsername = (u != null && u.isNotEmpty) ? u : null;
      authorAvatarUrl = (a != null && a.isNotEmpty) ? a : null;
    }

    final mySavedRaw = row['my_saved'];
    final mySaved = mySavedRaw is bool
        ? mySavedRaw
        : (mySavedRaw is String && (mySavedRaw == 'true' || mySavedRaw == 't'));

    String? myReaction;
    final reactionRaw = row['my_reaction'];
    if (reactionRaw is String) {
      final kind = reactionRaw.trim();
      if (kind == 'like' || kind == 'dislike') myReaction = kind;
    }

    bool? myFollowingAuthor;
    final followingRaw = row['my_following_author'];
    if (followingRaw is bool) {
      myFollowingAuthor = followingRaw;
    } else if (followingRaw is String) {
      myFollowingAuthor = followingRaw == 'true' || followingRaw == 't';
    }

    return PostFeedItem(
      post: post,
      authorUsername: authorUsername,
      authorAvatarUrl: authorAvatarUrl,
      myReaction: myReaction,
      mySaved: mySaved,
      myFollowingAuthor: myFollowingAuthor,
      marker: marker,
      profileFilters: profileFilters,
    );
  }
}
