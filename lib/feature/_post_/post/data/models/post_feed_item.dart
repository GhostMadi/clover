import 'package:clover/feature/_post_/post/data/models/post_booking_service_summary.dart';
import 'package:clover/feature/_post_/post/data/models/post_marker_summary.dart';
import 'package:clover/feature/_post_/post/data/models/post_model.dart';
import 'package:clover/feature/_post_/post/data/models/post_profile_filter_value.dart';

/// Карточка поста для ленты / детали: базовая строка `posts` + опциональные расширения.
///
/// ## Модель «Post + extensions»
///
/// Всегда есть [post]. Дополнительные сущности (ивент, позже — другие) вешаются
/// **только если на посте есть FK** — `post.marker_id`, `post.booking_service_id`:
///
/// | `post.marker_id` | Смысл | [marker] |
/// |------------------|-------|----------|
/// | пусто | обычная публикация | всегда `null`, маркер не запрашиваем |
/// | uuid | ивент | payload из enriched-RPC или `null` до догрузки |
///
/// Источник истины «это ивент?» — только [PostModel.hasMarker] / [isEvent],
/// не наличие [marker] в памяти.
///
/// [isMarkerPayloadPending] — `marker_id` есть, но enriched ещё не принёс `post.marker`
/// (скелетон на детали). [eventMarkerId] достаточен для archive/delete без payload.
class PostFeedItem {
  const PostFeedItem({
    required this.post,
    this.authorUsername,
    this.authorAvatarUrl,
    this.myReaction,
    this.mySaved = false,
    this.myFollowingAuthor,
    this.marker,
    this.bookingService,
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

  /// Payload ивента (маркер). Только если [isEvent]; иначе всегда `null`.
  final PostMarkerSummary? marker;

  /// Payload услуги записи. Только если [hasBookingService]; иначе `null`.
  final PostBookingServiceSummary? bookingService;

  /// Значения фильтров профиля, привязанные к посту (`profile_filters` в enriched).
  final List<PostProfileFilterValue> profileFilters;

  /// Ивент = у поста задан `marker_id` (продуктовый термин).
  bool get isEvent => post.isEvent;

  /// Id маркера с поста — хватает для archive/unarchive без [marker].
  String? get eventMarkerId => isEvent ? post.markerId?.trim() : null;

  /// `marker_id` есть, enriched-payload маркера ещё не в item (UI-скелетон).
  bool get isMarkerPayloadPending => isEvent && marker == null;

  /// Payload маркера уже есть или ивента нет.
  bool get isMarkerPayloadLoaded => !isEvent || marker != null;

  bool get hasBookingService => post.hasBookingService;

  /// `booking_service_id` есть, enriched-payload услуги ещё не в item.
  bool get isBookingServicePayloadPending => hasBookingService && bookingService == null;

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
    bool clearMarker = false,
    PostBookingServiceSummary? bookingService,
    bool clearBookingService = false,
    List<PostProfileFilterValue>? profileFilters,
  }) {
    return PostFeedItem(
      post: post ?? this.post,
      authorUsername: authorUsername ?? this.authorUsername,
      authorAvatarUrl: authorAvatarUrl ?? this.authorAvatarUrl,
      myReaction: clearMyReaction ? null : (myReaction ?? this.myReaction),
      mySaved: mySaved ?? this.mySaved,
      myFollowingAuthor: myFollowingAuthor ?? this.myFollowingAuthor,
      marker: clearMarker ? null : (marker ?? this.marker),
      bookingService: clearBookingService ? null : (bookingService ?? this.bookingService),
      profileFilters: profileFilters ?? this.profileFilters,
    );
  }
}
