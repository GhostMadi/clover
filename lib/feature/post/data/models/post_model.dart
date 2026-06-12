import 'package:clover/feature/post/data/models/post_media_model.dart';

/// Пост из `public.posts` + `post_media` (только картинки).
class PostModel {
  const PostModel({
    required this.id,
    required this.userId,
    this.clusterId,
    this.markerId,
    this.title,
    this.description,
    required this.likesCount,
    required this.dislikesCount,
    required this.commentsCount,
    required this.savesCount,
    required this.sendsCount,
    required this.createdAt,
    required this.media,
  });

  final String id;
  final String userId;
  final String? clusterId;
  final String? markerId;
  final String? title;
  final String? description;
  final int likesCount;
  final int dislikesCount;
  final int commentsCount;
  final int savesCount;
  final int sendsCount;
  final DateTime createdAt;
  final List<PostMediaModel> media;

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

    return PostModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      clusterId: (json['cluster_id'] as String?)?.trim(),
      markerId: (json['marker_id'] as String?)?.trim(),
      title: (json['title'] as String?)?.trim(),
      description: (json['description'] as String?)?.trim(),
      likesCount: (json['likes_count'] as num?)?.toInt() ?? 0,
      dislikesCount: (json['dislikes_count'] as num?)?.toInt() ?? 0,
      commentsCount: (json['comments_count'] as num?)?.toInt() ?? 0,
      savesCount: (json['saves_count'] as num?)?.toInt() ?? 0,
      sendsCount: (json['sends_count'] as num?)?.toInt() ?? 0,
      createdAt: ts('created_at'),
      media: media,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'cluster_id': clusterId,
    'marker_id': markerId,
    'title': title,
    'description': description,
    'likes_count': likesCount,
    'dislikes_count': dislikesCount,
    'comments_count': commentsCount,
    'saves_count': savesCount,
    'sends_count': sendsCount,
    'created_at': createdAt.toUtc().toIso8601String(),
    'post_media': media.map((e) => e.toJson()).toList(),
  };
}
