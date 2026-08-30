import 'package:clover/feature/_settings_/settings_filter/data/models/filter_category.dart';
import 'package:clover/feature/_settings_/settings_filter/data/repository/filter_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

@injectable
class ProfileFilterCubit extends Cubit<ProfileFilterState> {
  ProfileFilterCubit(this._repository) : super(const ProfileFilterState.initial());

  final FilterRepository _repository;

  String? _cachedProfileId;
  List<FilterCategory> _cachedCategories = const [];

  Future<List<FilterCategory>> ensureLoaded(String profileId) async {
    final id = profileId.trim();
    if (id.isEmpty) return const [];

    if (_cachedProfileId == id && state is ProfileFilterReady) {
      return _cachedCategories;
    }

    emit(const ProfileFilterState.loading());
    try {
      final categories = await _repository.listCategories(id);
      _cachedProfileId = id;
      _cachedCategories = categories;
      if (isClosed) return categories;
      emit(ProfileFilterState.ready(categories));
      return categories;
    } on FilterRepositoryException catch (e) {
      if (isClosed) rethrow;
      emit(ProfileFilterState.error(e.message));
      rethrow;
    } catch (e) {
      if (isClosed) rethrow;
      emit(ProfileFilterState.error('$e'));
      rethrow;
    }
  }

  void invalidate() {
    _cachedProfileId = null;
    _cachedCategories = const [];
    emit(const ProfileFilterState.initial());
  }
}

sealed class ProfileFilterState {
  const ProfileFilterState();

  const factory ProfileFilterState.initial() = ProfileFilterInitial;
  const factory ProfileFilterState.loading() = ProfileFilterLoading;
  const factory ProfileFilterState.ready(List<FilterCategory> categories) = ProfileFilterReady;
  const factory ProfileFilterState.error(String message) = ProfileFilterError;
}

final class ProfileFilterInitial extends ProfileFilterState {
  const ProfileFilterInitial();
}

final class ProfileFilterLoading extends ProfileFilterState {
  const ProfileFilterLoading();
}

final class ProfileFilterReady extends ProfileFilterState {
  const ProfileFilterReady(this.categories);
  final List<FilterCategory> categories;
}

final class ProfileFilterError extends ProfileFilterState {
  const ProfileFilterError(this.message);
  final String message;
}
