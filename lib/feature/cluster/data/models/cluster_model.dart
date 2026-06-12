/// Строка `public.clusters` (Supabase / PostgREST).
class ClusterModel {
  const ClusterModel({
    required this.id,
    required this.ownerId,
    required this.title,
    this.subtitle,
    this.coverUrl,
    required this.postsCount,
    required this.sortOrder,
    required this.isArchived,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String ownerId;
  final String title;
  final String? subtitle;
  final String? coverUrl;
  final int postsCount;
  final int sortOrder;
  final bool isArchived;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Подпись к счётчику постов в карточке (как в профиле).
  String get postsCountLabel {
    final n = postsCount;
    if (n <= 0) return 'Нет фото';
    return '$n фото';
  }

  factory ClusterModel.fromJson(Map<String, dynamic> json) {
    DateTime? ts(String key) {
      final v = json[key];
      if (v is String) return DateTime.tryParse(v);
      return null;
    }

    return ClusterModel(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      title: (json['title'] as String?)?.trim() ?? '',
      subtitle: (json['subtitle'] as String?)?.trim(),
      coverUrl: (json['cover_url'] as String?)?.trim(),
      postsCount: (json['posts_count'] as num?)?.toInt() ?? 0,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      isArchived: json['is_archived'] as bool? ?? false,
      createdAt: ts('created_at'),
      updatedAt: ts('updated_at'),
    );
  }
}
