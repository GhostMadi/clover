import 'package:clover/feature/_settings_/settings_filter/data/models/filter_category.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class FilterRepository {
  Future<List<FilterCategory>> listCategories(String profileId);

  Future<FilterCategory> upsertCategory({
    required String name,
    required List<String> values,
    String? categoryId,
  });

  Future<void> deleteCategory(String categoryId);

  /// Привязать выбранные значения фильтров к посту (`category_id:label`).
  Future<void> setPostFilters({
    required String postId,
    required Set<String> selectionKeys,
  });
}

class FilterRepositoryException implements Exception {
  FilterRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}

@LazySingleton(as: FilterRepository)
class FilterRepositoryImpl implements FilterRepository {
  FilterRepositoryImpl(this._client);

  final SupabaseClient _client;

  String? get _uid => _client.auth.currentUser?.id.trim();

  void _requireSession() {
    if (_uid == null || _uid!.isEmpty) {
      throw FilterRepositoryException('Нет сессии: войдите в аккаунт');
    }
  }

  @override
  Future<List<FilterCategory>> listCategories(String profileId) async {
    _requireSession();
    final id = profileId.trim();
    if (id.isEmpty) return const [];

    try {
      final res = await _client.rpc(
        'list_profile_filter_categories',
        params: {'p_profile_id': id},
      );

      if (res is! List) return const [];

      final categories = <FilterCategory>[];
      for (final raw in res) {
        if (raw is! Map) continue;
        categories.add(FilterCategory.fromJson(Map<String, dynamic>.from(raw)));
      }
      return categories;
    } on PostgrestException catch (e) {
      throw FilterRepositoryException(_messageFromPostgrest(e));
    }
  }

  @override
  Future<FilterCategory> upsertCategory({
    required String name,
    required List<String> values,
    String? categoryId,
  }) async {
    _requireSession();

    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw FilterRepositoryException('Укажите название категории');
    }
    if (values.isEmpty) {
      throw FilterRepositoryException('Добавьте хотя бы одно значение');
    }

    final trimmedId = categoryId?.trim();
    final params = <String, dynamic>{
      'p_name': trimmedName,
      'p_values': values,
      if (trimmedId != null && trimmedId.isNotEmpty) 'p_category_id': trimmedId,
    };

    try {
      final res = await _client.rpc('upsert_profile_filter_category', params: params);
      if (res is! Map) {
        throw FilterRepositoryException('Некорректный ответ сервера');
      }
      return FilterCategory.fromJson(Map<String, dynamic>.from(res));
    } on PostgrestException catch (e) {
      throw FilterRepositoryException(_messageFromPostgrest(e));
    }
  }

  @override
  Future<void> deleteCategory(String categoryId) async {
    _requireSession();
    final id = categoryId.trim();
    if (id.isEmpty) {
      throw FilterRepositoryException('Некорректная категория');
    }

    try {
      await _client.rpc('delete_profile_filter_category', params: {'p_category_id': id});
    } on PostgrestException catch (e) {
      throw FilterRepositoryException(_messageFromPostgrest(e));
    }
  }

  @override
  Future<void> setPostFilters({
    required String postId,
    required Set<String> selectionKeys,
  }) async {
    _requireSession();
    final id = postId.trim();
    if (id.isEmpty) return;
    if (selectionKeys.isEmpty) return;

    final keys = selectionKeys.map((e) => e.trim()).where((e) => e.isNotEmpty).toList(growable: false);
    if (keys.isEmpty) return;

    try {
      await _client.rpc(
        'set_post_profile_filters',
        params: {
          'p_post_id': id,
          'p_selection_keys': keys,
        },
      );
    } on PostgrestException catch (e) {
      throw FilterRepositoryException(_messageFromPostgrest(e));
    }
  }

  static String _messageFromPostgrest(PostgrestException e) {
    final code = e.code?.trim();
    final message = e.message.trim();

    return switch (code) {
      'P0003' => 'Войдите в аккаунт',
      'P0011' when message.contains('category_name_taken') => 'Категория с таким названием уже есть',
      'P0011' when message.contains('filter_value_taken') => 'Такое значение уже есть в категории',
      'P0008' when message.contains('category_not_found') => 'Категория не найдена',
      'P0007' when message.contains('filter_name_required') => 'Укажите название категории',
      'P0007' when message.contains('filter_values_required') => 'Добавьте хотя бы одно значение',
      _ => message.isNotEmpty ? message : 'Ошибка фильтров',
    };
  }
}
