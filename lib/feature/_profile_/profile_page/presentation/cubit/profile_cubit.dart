import 'package:clover/core/session/app_session.dart';
import 'package:clover/feature/_profile_/profile_page/data/model/profile_new_model.dart';
import 'package:clover/feature/_profile_/profile_page/data/repository/profile_local_cache.dart';
import 'package:clover/feature/_profile_/profile_page/data/repository/profile_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

part 'profile_cubit.freezed.dart';

@singleton
class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit(this._repository, this._cache, this._session)
      : super(const ProfileState.initial());

  final ProfileNewRepository _repository;
  final ProfileLocalCache _cache;
  final AppSession _session;

  /// Сброс после выхода из аккаунта (singleton не закрывается).
  void reset() {
    final uid = _session.userId ?? state.mapOrNull(loaded: (s) => s.profile.id);
    emit(const ProfileState.initial());
    if (uid != null && uid.isNotEmpty) {
      _cache.clear(uid);
    }
  }

  Future<void> load() async {
    final uid = _session.userId;
    final already = state.mapOrNull(loaded: (s) => s.profile);

    // Уже в памяти — не мигаем loading, только sync.
    if (already != null) {
      await _syncRemote();
      return;
    }

    if (uid != null && uid.isNotEmpty) {
      final cached = await _cache.read(uid);
      if (!isClosed && cached != null) {
        emit(ProfileState.loaded(cached));
      } else if (!isClosed) {
        emit(const ProfileState.loading());
      }
    } else if (!isClosed) {
      emit(const ProfileState.loading());
    }

    await _syncRemote();
  }

  Future<void> _syncRemote() async {
    try {
      final profile = await _repository.getCurrent();
      if (isClosed) return;
      if (profile == null) {
        final had = state.mapOrNull(loaded: (_) => true) ?? false;
        if (!had) {
          emit(const ProfileState.error('Профиль не найден'));
        }
        return;
      }
      emit(ProfileState.loaded(profile));
      await _cache.write(profile);
    } catch (e) {
      if (isClosed) return;
      final had = state.mapOrNull(loaded: (_) => true) ?? false;
      if (!had) {
        emit(ProfileState.error('$e'));
      }
    }
  }

  /// Обновить профиль в памяти (например после редактирования).
  void applyProfile(ProfileNewModel profile) {
    emit(ProfileState.loaded(profile));
    _cache.write(profile);
  }

  /// Локально обновить флаг фильтров (после CRUD в настройках).
  void patchHasFilters(bool hasFilters) {
    final loaded = state.mapOrNull(loaded: (s) => s);
    if (loaded == null) return;
    final next = loaded.profile.copyWith(hasFilters: hasFilters);
    emit(ProfileState.loaded(next));
    _cache.write(next);
  }

  /// Обновление по pull-to-refresh без полного скелетона, если уже есть данные.
  Future<void> refresh() async {
    final hadData = state.mapOrNull(loaded: (_) => true) ?? false;
    if (!hadData) {
      await load();
      return;
    }
    await _syncRemote();
  }
}

@freezed
class ProfileState with _$ProfileState {
  const factory ProfileState.initial() = _Initial;
  const factory ProfileState.loading() = _Loading;
  const factory ProfileState.loaded(ProfileNewModel profile) = _Loaded;
  const factory ProfileState.error(String message) = _Error;
}
