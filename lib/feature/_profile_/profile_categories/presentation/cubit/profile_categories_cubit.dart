import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
  import 'package:clover/feature/profile_categories/data/models/profile_category_model.dart';
import 'package:clover/feature/profile_categories/data/repository/profile_categories_repository.dart';

part 'profile_categories_cubit.freezed.dart';

@lazySingleton
class ProfileCategoriesCubit extends Cubit<ProfileCategoriesState> {
  ProfileCategoriesCubit(this._repository) : super(const ProfileCategoriesState.initial());

  final ProfileCategoriesRepository _repository;

  Future<void> load() async {
    emit(const ProfileCategoriesState.loading());
    try {
      final items = await _repository.fetchActiveOrdered();
      emit(ProfileCategoriesState.loaded(items));
    } catch (e) {
      emit(ProfileCategoriesState.error('$e'));
    }
  }
}

@freezed
class ProfileCategoriesState with _$ProfileCategoriesState {
  const factory ProfileCategoriesState.initial() = _Initial;
  const factory ProfileCategoriesState.loading() = _Loading;
  const factory ProfileCategoriesState.loaded(List<ProfileCategoryModel> items) = _Loaded;
  const factory ProfileCategoriesState.error(String message) = _Error;
}
