import 'package:clover/feature/_bonus_/shared/data/models/bonus_program_status.dart';
import 'package:clover/feature/_profile_/profile_page/data/model/profile_new_model.dart';
import 'package:clover/feature/_profile_/profile_page/data/repository/profile_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

part 'profile_cubit.freezed.dart';

@singleton
class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit(this._repository) : super(const ProfileState.initial());

  final ProfileNewRepository _repository;

  /// Сброс после выхода из аккаунта (singleton не закрывается).
  void reset() {
    emit(const ProfileState.initial());
  }

  Future<void> load() async {
    emit(const ProfileState.loading());
    try {
      final profile = await _repository.getCurrent();
      if (profile == null) {
        emit(const ProfileState.error('Профиль не найден'));
        return;
      }
      emit(ProfileState.loaded(profile));
    } catch (e) {
      emit(ProfileState.error('$e'));
    }
  }

  /// Обновить профиль в памяти (например после редактирования).
  void applyProfile(ProfileNewModel profile) {
    emit(ProfileState.loaded(profile));
  }

  /// Локально обновить флаг фильтров (после CRUD в настройках).
  void patchHasFilters(bool hasFilters) {
    final loaded = state.mapOrNull(loaded: (s) => s);
    if (loaded == null) return;
    emit(ProfileState.loaded(loaded.profile.copyWith(hasFilters: hasFilters)));
  }

  /// Локально обновить статус бонусной программы (после настроек).
  void patchBonusProgramStatus(BonusProgramStatus status) {
    final loaded = state.mapOrNull(loaded: (s) => s);
    if (loaded == null) return;
    emit(ProfileState.loaded(loaded.profile.copyWith(bonusProgramStatus: status)));
  }

  /// Обновление по pull-to-refresh без полного скелетона, если уже есть данные.
  Future<void> refresh() async {
    final hadData = state.mapOrNull(loaded: (_) => true) ?? false;
    if (!hadData) {
      await load();
      return;
    }
    try {
      final profile = await _repository.getCurrent();
      if (profile == null) return;
      emit(ProfileState.loaded(profile));
    } catch (_) {
      // оставляем предыдущий профиль при сбое сети
    }
  }
}

@freezed
class ProfileState with _$ProfileState {
  const factory ProfileState.initial() = _Initial;
  const factory ProfileState.loading() = _Loading;
  const factory ProfileState.loaded(ProfileNewModel profile) = _Loaded;
  const factory ProfileState.error(String message) = _Error;
}
