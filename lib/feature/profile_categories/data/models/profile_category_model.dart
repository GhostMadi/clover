/// Строка `public.profile_categories`.
class ProfileCategoryModel {
  const ProfileCategoryModel({required this.code, required this.isActive, required this.sortOrder});

  final String code;
  final bool isActive;
  final int sortOrder;

  factory ProfileCategoryModel.fromJson(Map<String, dynamic> json) {
    return ProfileCategoryModel(
      code: json['code'] as String,
      isActive: json['is_active'] as bool? ?? true,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );
  }
}
