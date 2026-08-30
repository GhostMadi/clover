import 'package:clover/feature/_profile_/profile_page/data/model/profile_new_model.dart';
import 'package:clover/feature/_profile_/profile_page/data/repository/profile_repository.dart';
import 'package:clover/feature/_catalog_/social_graph/data/repository/social_graph_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'guest_profile_cubit.freezed.dart';

@injectable
class GuestProfileCubit extends Cubit<GuestProfileState> {
  GuestProfileCubit(this._repository, this._socialGraph) : super(const GuestProfileState.initial());

  final ProfileNewRepository _repository;
  final SocialGraphRepository _socialGraph;
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
      emit(const GuestProfileState.error('Некорректный профиль'));
      return;
    }
    _userId = id;
    emit(const GuestProfileState.loading());
    try {
      final profile = await _repository.getById(id);
      if (profile == null) {
        emit(const GuestProfileState.error('Профиль не найден'));
        return;
      }
      final isFollowing = await _loadIsFollowing(id);
      if (isClosed) return;
      emit(GuestProfileState.loaded(profile: profile, isFollowing: isFollowing));
    } catch (e) {
      if (isClosed) return;
      emit(GuestProfileState.error('$e'));
    }
  }

  Future<void> refresh() async {
    final id = _userId?.trim();
    if (id == null || id.isEmpty) return;

    final hadData = state.mapOrNull(loaded: (_) => true) ?? false;
    if (!hadData) {
      await load(id);
      return;
    }

    try {
      final profile = await _repository.getById(id);
      if (profile == null) return;
      final isFollowing = await _loadIsFollowing(id);
      if (isClosed) return;
      emit(GuestProfileState.loaded(profile: profile, isFollowing: isFollowing));
    } catch (_) {
      // оставляем предыдущий профиль при сбое сети
    }
  }

  Future<void> toggleFollow() async {
    final loaded = state.mapOrNull(loaded: (s) => s);
    if (loaded == null || !canToggleFollow) return;

    final targetId = loaded.profile.id.trim();
    if (targetId.isEmpty) return;

    emit(loaded.copyWith(isFollowUpdating: true));
    try {
      if (loaded.isFollowing) {
        await _socialGraph.unfollowUser(targetId);
      } else {
        await _socialGraph.followUser(targetId);
      }
      if (isClosed) return;
      emit(loaded.copyWith(isFollowing: !loaded.isFollowing, isFollowUpdating: false));
    } catch (_) {
      if (isClosed) return;
      emit(loaded.copyWith(isFollowUpdating: false));
    }
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
