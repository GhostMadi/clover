import 'package:clover/feature/_catalog_/marker_tags/data/models/marker_tag_model.dart';
import 'package:clover/feature/_post_/post/data/models/post_media_model.dart';

/// Пост из `public.posts` + `post_media` (только картинки).
class PostModel {
  const PostModel({
    required this.id,
    required this.userId,
    this.clusterId,
    this.markerId,
    this.title,
    this.description,
    this.textEmoji,
    this.locationId,
    this.addressPrimary,
    this.addressCyrillic,
    this.countryCode,
    this.cityCode,
    required this.likesCount,
    required this.dislikesCount,
    required this.commentsCount,
    required this.savesCount,
    required this.sendsCount,
    required this.createdAt,
    required this.media,
    this.tags = const [],
  });

  final String id;
  final String userId;
  final String? clusterId;
  final String? markerId;
  final String? title;
  final String? description;
  final String? textEmoji;
  final String? locationId;
  final String? addressPrimary;
  final String? addressCyrillic;
  final String? countryCode;
  final String? cityCode;
  final int likesCount;
  final int dislikesCount;
  final int commentsCount;
  final int savesCount;
  final int sendsCount;
  final DateTime createdAt;
  final List<PostMediaModel> media;
  final List<MarkerTagModel> tags;

  bool get hasMarker {
    final m = markerId?.trim();
    return m != null && m.isNotEmpty;
  }

  List<PostMediaModel> get sortedMedia {
    final sorted = List<PostMediaModel>.from(media)..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return List.unmodifiable(sorted);
  }

  PostMediaModel? get coverMedia => sortedMedia.isEmpty ? null : sortedMedia.first;

  factory PostModel.fromJson(Map<String, dynamic> json) {
    DateTime ts(String key) {
      final v = json[key];
      if (v is String) return DateTime.tryParse(v) ?? DateTime.fromMillisecondsSinceEpoch(0);
      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    final mediaRaw = json['post_media'];
    final media = <PostMediaModel>[];
    if (mediaRaw is List) {
      for (final item in mediaRaw) {
        if (item is! Map) continue;
        final m = PostMediaModel.tryFromJson(Map<String, dynamic>.from(item));
        if (m != null) media.add(m);
      }
      media.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    }

    final tagsRaw = json['tags'];
    final tags = <MarkerTagModel>[];
    if (tagsRaw is List) {
      for (final item in tagsRaw) {
        if (item is! Map) continue;
        tags.add(MarkerTagModel.fromJson(Map<String, dynamic>.from(item)));
      }
    }

    return PostModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      clusterId: (json['cluster_id'] as String?)?.trim(),
      markerId: (json['marker_id'] as String?)?.trim(),
      title: (json['title'] as String?)?.trim(),
      description: (json['description'] as String?)?.trim(),
      textEmoji: (json['text_emoji'] as String?)?.trim(),
      locationId: (json['location_id'] as String?)?.trim(),
      addressPrimary: (json['address_primary'] as String?)?.trim(),
      addressCyrillic: (json['address_cyrillic'] as String?)?.trim(),
      countryCode: (json['country_code'] as String?)?.trim().toLowerCase(),
      cityCode: (json['city_code'] as String?)?.trim(),
      likesCount: (json['likes_count'] as num?)?.toInt() ?? 0,
      dislikesCount: (json['dislikes_count'] as num?)?.toInt() ?? 0,
      commentsCount: (json['comments_count'] as num?)?.toInt() ?? 0,
      savesCount: (json['saves_count'] as num?)?.toInt() ?? 0,
      sendsCount: (json['sends_count'] as num?)?.toInt() ?? 0,
      createdAt: ts('created_at'),
      media: media,
      tags: List.unmodifiable(tags),
    );
  }

  PostModel copyWith({
    String? id,
    String? userId,
    String? clusterId,
    bool clearClusterId = false,
    String? markerId,
    String? title,
    String? description,
    String? textEmoji,
    String? locationId,
    String? addressPrimary,
    String? addressCyrillic,
    String? countryCode,
    String? cityCode,
    int? likesCount,
    int? dislikesCount,
    int? commentsCount,
    int? savesCount,
    int? sendsCount,
    DateTime? createdAt,
    List<PostMediaModel>? media,
    List<MarkerTagModel>? tags,
  }) {
    return PostModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      clusterId: clearClusterId ? null : (clusterId ?? this.clusterId),
      markerId: markerId ?? this.markerId,
      title: title ?? this.title,
      description: description ?? this.description,
      textEmoji: textEmoji ?? this.textEmoji,
      locationId: locationId ?? this.locationId,
      addressPrimary: addressPrimary ?? this.addressPrimary,
      addressCyrillic: addressCyrillic ?? this.addressCyrillic,
      countryCode: countryCode ?? this.countryCode,
      cityCode: cityCode ?? this.cityCode,
      likesCount: likesCount ?? this.likesCount,
      dislikesCount: dislikesCount ?? this.dislikesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      savesCount: savesCount ?? this.savesCount,
      sendsCount: sendsCount ?? this.sendsCount,
      createdAt: createdAt ?? this.createdAt,
      media: media ?? this.media,
      tags: tags ?? this.tags,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'cluster_id': clusterId,
    'marker_id': markerId,
    'title': title,
    'description': description,
    'text_emoji': textEmoji,
    'location_id': locationId,
    'address_primary': addressPrimary,
    'address_cyrillic': addressCyrillic,
    'country_code': countryCode,
    'city_code': cityCode,
    'likes_count': likesCount,
    'dislikes_count': dislikesCount,
    'comments_count': commentsCount,
    'saves_count': savesCount,
    'sends_count': sendsCount,
    'created_at': createdAt.toUtc().toIso8601String(),
    'post_media': media.map((e) => e.toJson()).toList(),
    'tags': tags.map((e) => e.toJson()).toList(),
  };
}
