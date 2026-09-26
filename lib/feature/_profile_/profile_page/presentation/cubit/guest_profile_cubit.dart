import 'package:clover/feature/_catalog_/social_graph/data/repository/social_graph_repository.dart';
import 'package:clover/feature/_profile_/profile_page/data/model/profile_new_model.dart';
import 'package:clover/feature/_profile_/profile_page/data/repository/profile_local_cache.dart';
import 'package:clover/feature/_profile_/profile_page/data/repository/profile_repository.dart';
import 'package:clover/feature/_profile_/profile_page/presentation/cubit/profile_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/locale/app_locale_cubit.dart';
import 'package:clover/l10n/app_localizations.dart';

part 'guest_profile_cubit.freezed.dart';

@injectable
class GuestProfileCubit extends Cubit<GuestProfileState> {
  GuestProfileCubit(
    this._repository,
    this._socialGraph,
    this._ownProfile,
    this._cache,
  ) : super(const GuestProfileState.initial());

  final ProfileNewRepository _repository;
  final SocialGraphRepository _socialGraph;
  final ProfileCubit _ownProfile;
  final ProfileLocalCache _cache;
  String? _userId;

  bool get canToggleFollow {
    final id = _userId?.trim();
    if (id == null || id.isEmpty) return false;
    final currentUid = Supabase.instance.client.auth.currentUser?.id.trim();
    if (currentUid == null || currentUid.isEmpty) return false;
    return currentUid != id;
  }

  Future<void> load(String userId) async {
    final id = userId.trim();
    if (id.isEmpty) {
      emit(GuestProfileState.error(lookupAppLocalizations(sl<AppLocaleCubit>().state.locale).profile_invalid));
      return;
    }
    _userId = id;

    final cachedProfile = _cache.readMemoryProfile(id);
    final cachedFollowing = _cache.readMemoryFollowing(id);
    if (cachedProfile != null) {
      emit(
        GuestProfileState.loaded(
          profile: cachedProfile,
          isFollowing: cachedFollowing ?? false,
        ),
      );
      await _syncRemote(id, showErrorIfEmpty: false);
      return;
    }

    emit(const GuestProfileState.loading());
    await _syncRemote(id, showErrorIfEmpty: true);
  }

  Future<void> refresh() async {
    final id = _userId?.trim();
    if (id == null || id.isEmpty) return;

    final hadData = state.mapOrNull(loaded: (_) => true) ?? false;
    if (!hadData) {
      await load(id);
      return;
    }

    await _syncRemote(id, showErrorIfEmpty: false);
  }

  Future<void> _syncRemote(String id, {required bool showErrorIfEmpty}) async {
    try {
      final profile = await _repository.getById(id);
      if (profile == null) {
        if (showErrorIfEmpty && !isClosed) {
          emit(GuestProfileState.error(lookupAppLocalizations(sl<AppLocaleCubit>().state.locale).profile_not_found));
        }
        return;
      }
      final isFollowing = await _loadIsFollowing(id);
      if (isClosed) return;
      _cache.putMemoryProfile(profile);
      if (canToggleFollow) {
        _cache.putMemoryFollowing(id, isFollowing);
      }
      emit(GuestProfileState.loaded(profile: profile, isFollowing: isFollowing));
    } catch (e) {
      if (isClosed) return;
      final had = state.mapOrNull(loaded: (_) => true) ?? false;
      if (!had && showErrorIfEmpty) {
        emit(GuestProfileState.error('$e'));
      }
    }
  }

  Future<void> toggleFollow() async {
    final loaded = state.mapOrNull(loaded: (s) => s);
    if (loaded == null || !canToggleFollow) return;

    final targetId = loaded.profile.id.trim();
    if (targetId.isEmpty) return;

    emit(loaded.copyWith(isFollowUpdating: true));
    try {
      final nextFollowing = !loaded.isFollowing;
      if (loaded.isFollowing) {
        await _socialGraph.unfollowUser(targetId);
      } else {
        await _socialGraph.followUser(targetId);
      }
      if (isClosed) return;

      final delta = nextFollowing ? 1 : -1;
      final nextFollowers = loaded.profile.followersCount + delta;
      final patched = loaded.profile.copyWith(
        followersCount: nextFollowers < 0 ? 0 : nextFollowers,
      );
      _ownProfile.adjustFollowingCount(delta);
      _cache.putMemoryProfile(patched);
      _cache.putMemoryFollowing(targetId, nextFollowing);
      emit(
        loaded.copyWith(
          profile: patched,
          isFollowing: nextFollowing,
          isFollowUpdating: false,
        ),
      );
    } catch (_) {
      if (isClosed) return;
      emit(loaded.copyWith(isFollowUpdating: false));
    }
  }

  /// Blocks [target]; caller should leave the guest screen after success.
  Future<void> blockUser() async {
    final loaded = state.mapOrNull(loaded: (s) => s);
    if (loaded == null || !canToggleFollow) return;

    final targetId = loaded.profile.id.trim();
    if (targetId.isEmpty) return;

    await _socialGraph.blockUser(targetId);
    _cache.putMemoryFollowing(targetId, false);
  }

  Future<bool> _loadIsFollowing(String targetUserId) async {
    if (!canToggleFollow) return false;
    return _socialGraph.isFollowingUser(targetUserId);
  }
}

@freezed
class GuestProfileState with _$GuestProfileState {
  const factory GuestProfileState.initial() = _Initial;
  const factory GuestProfileState.loading() = _Loading;
  const factory GuestProfileState.loaded({
    required ProfileNewModel profile,
    required bool isFollowing,
    @Default(false) bool isFollowUpdating,
  }) = _Loaded;
  const factory GuestProfileState.error(String message) = _Error;
}
