import 'package:clover/core/post_media/post_media.dart';

/// Медиа поста (только изображения; видео отфильтровываются при парсинге).
class PostMediaModel {
  const PostMediaModel({
    required this.id,
    required this.postId,
    required this.url,
    required this.sortOrder,
    this.blurHash,
  });

  final String id;
  final String postId;
  final String url;
  final int sortOrder;
  final String? blurHash;

  PostAspectRatio get aspectRatio => PostAspectRatio.fromUrl(url);

  /// URL для плитки в сетке.
  String? get previewImageUrl {
    final u = url.trim();
    return u.isEmpty ? null : u;
  }

  factory PostMediaModel.fromJson(Map<String, dynamic> json) {
    return PostMediaModel(
      id: json['id'] as String,
      postId: json['post_id'] as String,
      url: (json['url'] as String?)?.trim() ?? '',
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      blurHash: (json['blur_hash'] as String?)?.trim(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'post_id': postId,
    'url': url,
    'sort_order': sortOrder,
    if (blurHash != null) 'blur_hash': blurHash,
  };

  /// Пропускаем видео и неизвестные типы.
  static PostMediaModel? tryFromJson(Map<String, dynamic> json) {
    final type = (json['type'] as String?)?.toLowerCase();
    if (type == 'video') return null;
    if (type != null && type != 'image') return null;
    return PostMediaModel.fromJson(json);
  }
}
