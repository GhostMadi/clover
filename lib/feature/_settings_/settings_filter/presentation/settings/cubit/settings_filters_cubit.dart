import 'package:clover/feature/profile_page/presentation/cubit/profile_cubit.dart';
import 'package:clover/feature/settings_filter/data/models/filter_category.dart';
import 'package:clover/feature/settings_filter/data/repository/filter_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'settings_filters_cubit.freezed.dart';

@injectable
class SettingsFiltersCubit extends Cubit<SettingsFiltersState> {
  SettingsFiltersCubit(this._repository, this._client, this._profileCubit)
      : super(const SettingsFiltersState.initial());

  final FilterRepository _repository;
  final SupabaseClient _client;
  final ProfileCubit _profileCubit;

  Future<void> load() async {
    final uid = _client.auth.currentUser?.id.trim();
    if (uid == null || uid.isEmpty) {
      emit(const SettingsFiltersState.error('Нет сессии'));
      return;
    }

    emit(const SettingsFiltersState.loading());
    try {
      final categories = await _repository.listCategories(uid);
      if (isClosed) return;
      emit(SettingsFiltersState.loaded(categories: categories));
    } on FilterRepositoryException catch (e) {
      if (isClosed) return;
      emit(SettingsFiltersState.error(e.message));
    } catch (e) {
      if (isClosed) return;
      emit(SettingsFiltersState.error('$e'));
    }
  }

  Future<String?> upsert(FilterCategory draft) async {
    final loaded = state.mapOrNull(loaded: (s) => s);
    if (loaded == null) return 'Подождите загрузку';

    emit(loaded.copyWith(isMutating: true));
    try {
      final saved = await _repository.upsertCategory(
        name: draft.name,
        values: draft.values,
        categoryId: draft.isNew ? null : draft.id,
      );

      final categories = draft.isNew
          ? [...loaded.categories, saved]
          : [
              for (final item in loaded.categories)
                if (item.id == saved.id) saved else item,
            ];

      if (isClosed) return null;
      emit(SettingsFiltersState.loaded(categories: categories));
      _profileCubit.patchHasFilters(categories.isNotEmpty);
      return null;
    } on FilterRepositoryException catch (e) {
      if (isClosed) return e.message;
      emit(loaded.copyWith(isMutating: false));
      return e.message;
    } catch (e) {
      if (isClosed) return '$e';
      emit(loaded.copyWith(isMutating: false));
      return '$e';
    }
  }

  Future<String?> deleteCategory(String categoryId) async {
    final loaded = state.mapOrNull(loaded: (s) => s);
    if (loaded == null) return 'Подождите загрузку';

    emit(loaded.copyWith(isMutating: true));
    try {
      await _repository.deleteCategory(categoryId);
      final categories = loaded.categories.where((c) => c.id != categoryId).toList(growable: false);

      if (isClosed) return null;
      emit(SettingsFiltersState.loaded(categories: categories));
      _profileCubit.patchHasFilters(categories.isNotEmpty);
      return null;
    } on FilterRepositoryException catch (e) {
      if (isClosed) return e.message;
      emit(loaded.copyWith(isMutating: false));
      return e.message;
    } catch (e) {
      if (isClosed) return '$e';
      emit(loaded.copyWith(isMutating: false));
      return '$e';
    }
  }
}

@freezed
class SettingsFiltersState with _$SettingsFiltersState {
  const factory SettingsFiltersState.initial() = _Initial;
  const factory SettingsFiltersState.loading() = _Loading;
  const factory SettingsFiltersState.loaded({
    required List<FilterCategory> categories,
    @Default(false) bool isMutating,
  }) = _Loaded;
  const factory SettingsFiltersState.error(String message) = _Error;
}
