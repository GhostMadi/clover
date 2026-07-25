import 'package:clover/core/catalog_sync/catalog_sync_kind.dart';

/// Глобальные версии справочников (одинаковы для всех пользователей).
class SyncMeta {
  const SyncMeta({
    required this.countries,
    required this.cities,
    required this.tags,
    required this.currencies,
    required this.categories,
  });

  final String countries;
  final String cities;
  final String tags;
  final String currencies;
  final String categories;

  String versionFor(CatalogSyncKind kind) => switch (kind) {
    CatalogSyncKind.countries => countries,
    CatalogSyncKind.cities => cities,
    CatalogSyncKind.tags => tags,
    CatalogSyncKind.currencies => currencies,
    CatalogSyncKind.categories => categories,
  };

  factory SyncMeta.fromJson(Map<String, dynamic> json) {
    String read(String key) => (json[key] as Object?)?.toString().trim() ?? '';

    return SyncMeta(
      countries: read('countries'),
      cities: read('cities'),
      tags: read('tags'),
      currencies: read('currencies'),
      categories: read('categories'),
    );
  }

  Map<String, dynamic> toJson() => {
    'countries': countries,
    'cities': cities,
    'tags': tags,
    'currencies': currencies,
    'categories': categories,
  };

  /// Пустые версии — считаем метаданные недоступными.
  bool get isValid =>
      countries.isNotEmpty &&
      cities.isNotEmpty &&
      tags.isNotEmpty &&
      currencies.isNotEmpty &&
      categories.isNotEmpty;
}
