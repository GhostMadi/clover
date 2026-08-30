import 'package:clover/feature/_post_/post/data/models/post_marker_summary.dart';
import 'package:clover/feature/_post_/post/data/models/post_model.dart';
import 'package:clover/feature/_post_/post/data/models/post_profile_filter_value.dart';

/// Пост + мини-данные автора и «сохранено мной» из enriched-RPC.
class PostFeedItem {
  const PostFeedItem({
    required this.post,
    this.authorUsername,
    this.authorAvatarUrl,
    this.myReaction,
    this.mySaved = false,
    this.myFollowingAuthor,
    this.marker,
    this.profileFilters = const [],
  });

  final PostModel post;
  final String? authorUsername;
  final String? authorAvatarUrl;

  /// `like` | `dislike` | null
  final String? myReaction;
  final bool mySaved;

  /// Подписан ли текущий пользователь на автора поста (`get_post_enriched`).
  final bool? myFollowingAuthor;

  /// Данные маркера, если пост привязан к событию.
  final PostMarkerSummary? marker;

  /// Значения фильтров профиля, привязанные к посту (`profile_filters` в enriched).
  final List<PostProfileFilterValue> profileFilters;

  bool get isLiked => myReaction == 'like';
  bool get isDisliked => myReaction == 'dislike';

  PostFeedItem copyWith({
    PostModel? post,
    String? authorUsername,
    String? authorAvatarUrl,
    String? myReaction,
    bool clearMyReaction = false,
    bool? mySaved,
    bool? myFollowingAuthor,
    PostMarkerSummary? marker,
    List<PostProfileFilterValue>? profileFilters,
  }) {
    return PostFeedItem(
      post: post ?? this.post,
      authorUsername: authorUsername ?? this.authorUsername,
      authorAvatarUrl: authorAvatarUrl ?? this.authorAvatarUrl,
      myReaction: clearMyReaction ? null : (myReaction ?? this.myReaction),
      mySaved: mySaved ?? this.mySaved,
      myFollowingAuthor: myFollowingAuthor ?? this.myFollowingAuthor,
      marker: marker ?? this.marker,
      profileFilters: profileFilters ?? this.profileFilters,
    );
  }
}
