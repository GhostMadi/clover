class PostProfileFilterValue {
  const PostProfileFilterValue({
    required this.categoryId,
    required this.categoryName,
    required this.label,
  });

  final String categoryId;
  final String categoryName;
  final String label;

  factory PostProfileFilterValue.fromJson(Map<String, dynamic> json) {
    return PostProfileFilterValue(
      categoryId: '${json['category_id']}',
      categoryName: '${json['category_name']}',
      label: '${json['label']}',
    );
  }

  static List<PostProfileFilterValue> listFromJson(dynamic raw) {
    if (raw is! List) return const [];

    final items = <PostProfileFilterValue>[];
    for (final entry in raw) {
      if (entry is! Map) continue;
      items.add(PostProfileFilterValue.fromJson(Map<String, dynamic>.from(entry)));
    }
    return List.unmodifiable(items);
  }
}
