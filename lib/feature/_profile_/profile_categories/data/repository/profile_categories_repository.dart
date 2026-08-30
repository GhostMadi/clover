import 'package:clover/feature/profile_categories/data/models/profile_category_model.dart';

abstract class ProfileCategoriesRepository {
  Future<List<ProfileCategoryModel>> fetchActiveOrdered();
}
