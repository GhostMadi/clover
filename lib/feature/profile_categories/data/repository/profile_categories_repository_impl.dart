import 'package:injectable/injectable.dart';
import 'package:clover/feature/profile_categories/data/models/profile_category_model.dart';
import 'package:clover/feature/profile_categories/data/repository/profile_categories_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

@LazySingleton(as: ProfileCategoriesRepository)
class ProfileCategoriesRepositoryImpl implements ProfileCategoriesRepository {
  ProfileCategoriesRepositoryImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<List<ProfileCategoryModel>> fetchActiveOrdered() async {
    final data = await _client
        .from('profile_categories')
        .select()
        .eq('is_active', true)
        .order('sort_order', ascending: true);
    final list = data as List<dynamic>;
    return list
        .map((e) => ProfileCategoryModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}
