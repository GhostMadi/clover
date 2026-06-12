/// Строка `public.countries`.
class CountryModel {
  const CountryModel({
    required this.code,
    required this.isActive,
    required this.sortOrder,
  });

  final String code;
  final bool isActive;
  final int sortOrder;

  factory CountryModel.fromJson(Map<String, dynamic> json) {
    return CountryModel(
      code: json['code'] as String,
      isActive: json['is_active'] as bool? ?? true,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );
  }
}
