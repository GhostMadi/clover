import 'package:clover/feature/_profile_/followers_and_followings/data/models/follow_profile_row.dart';
import 'package:clover/feature/_profile_/followers_and_followings/data/repository/followers_and_followings_repository.dart';
import 'package:clover/feature/_catalog_/social_graph/data/repository/social_graph_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

@injectable
class FollowersAndFollowingsCubit extends Cubit<FollowersAndFollowingsState> {
  FollowersAndFollowingsCubit(this._repository, this._socialGraph)
      : super(const FollowersAndFollowingsState.initial());

  final FollowersAndFollowingsRepository _repository;
  final SocialGraphRepository _socialGraph;

  String? _profileId;
  String? _currentUserId;

  Future<void> load(String profileId, {int initialTabIndex = 0}) async {
    if (isClosed) return;

    final id = profileId.trim();
    if (id.isEmpty) {
      emit(const FollowersAndFollowingsState.error('Некорректный профиль'));
      return;
    }

    _profileId = id;
    _currentUserId = Supabase.instance.client.auth.currentUser?.id.trim();

    emit(
      FollowersAndFollowingsState.loaded(
        tabIndex: initialTabIndex.clamp(0, 1),
        following: const [],
        followers: const [],
        followingLoading: true,
        followersLoading: true,
      ),
    );

    await Future.wait([_loadFollowing(), _loadFollowers()]);
  }

  void setTab(int index) {
    final cur = state;
    if (cur is! FollowersAndFollowingsLoaded) return;
    emit(cur.copyWith(tabIndex: index.clamp(0, 1)));
  }

  Future<void> refresh() async {
    final id = _profileId;
    if (id == null || id.isEmpty) return;

    final cur = state;
    if (cur is FollowersAndFollowingsLoaded) {
      emit(
        cur.copyWith(
          followingLoading: true,
          followersLoading: true,
          clearFollowingError: true,
          clearFollowersError: true,
        ),
      );
    }

    await Future.wait([_loadFollowing(), _loadFollowers()]);
  }

  Future<void> toggleFollow(String targetUserId, {required bool isFollowingTab}) async {
    final cur = state;
    if (cur is! FollowersAndFollowingsLoaded) return;

    final id = targetUserId.trim();
    if (id.isEmpty) return;

    final uid = _currentUserId;
    if (uid == null || uid.isEmpty || uid == id) return;

    final updated = _setRowUpdating(cur, id, isFollowingTab: isFollowingTab, updating: true);
    emit(updated);

    final snapshot = _rowById(updated, id, isFollowingTab: isFollowingTab);
    if (snapshot == null) return;

    final nextFollowing = !snapshot.isFollowing;

    try {
      if (nextFollowing) {
        await _socialGraph.followUser(id);
      } else {
        await _socialGraph.unfollowUser(id);
      }
      if (isClosed) return;

      final latest = state;
      if (latest is! FollowersAndFollowingsLoaded) return;

      emit(
        _patchRow(
          latest,
          id,
          isFollowingTab: isFollowingTab,
          patch: (row) => row.copyWith(isFollowing: nextFollowing, isFollowUpdating: false),
        ),
      );
    } catch (_) {
      if (isClosed) return;

      final latest = state;
      if (latest is! FollowersAndFollowingsLoaded) return;

      emit(
        _patchRow(
          latest,
          id,
          isFollowingTab: isFollowingTab,
          patch: (row) => row.copyWith(isFollowUpdating: false),
        ),
      );
    }
  }

  Future<void> _loadFollowing() async {
    final id = _profileId;
    if (id == null) return;

    try {
      final rows = await _repository.listFollowing(id);
      if (isClosed) return;

      final cur = state;
      if (cur is! FollowersAndFollowingsLoaded) return;

      emit(
        cur.copyWith(
          following: rows,
          followingLoading: false,
          clearFollowingError: true,
        ),
      );
    } catch (e) {
      if (isClosed) return;

      final cur = state;
      if (cur is! FollowersAndFollowingsLoaded) return;

      emit(
        cur.copyWith(
          followingLoading: false,
          followingError: '$e',
        ),
      );
    }
  }

  Future<void> _loadFollowers() async {
    final id = _profileId;
    if (id == null) return;

    try {
      final rows = await _repository.listFollowers(id);
      if (isClosed) return;

      final cur = state;
      if (cur is! FollowersAndFollowingsLoaded) return;

      emit(
        cur.copyWith(
          followers: rows,
          followersLoading: false,
          clearFollowersError: true,
        ),
      );
    } catch (e) {
      if (isClosed) return;

      final cur = state;
      if (cur is! FollowersAndFollowingsLoaded) return;

      emit(
        cur.copyWith(
          followersLoading: false,
          followersError: '$e',
        ),
      );
    }
  }

  FollowProfileRow? _rowById(FollowersAndFollowingsLoaded state, String id, {required bool isFollowingTab}) {
    final list = isFollowingTab ? state.following : state.followers;
    for (final row in list) {
      if (row.profileId == id) return row;
    }
    return null;
  }

  FollowersAndFollowingsLoaded _setRowUpdating(
    FollowersAndFollowingsLoaded state,
    String id, {
    required bool isFollowingTab,
    required bool updating,
  }) {
    return _patchRow(
      state,
      id,
      isFollowingTab: isFollowingTab,
      patch: (row) => row.copyWith(isFollowUpdating: updating),
    );
  }

  FollowersAndFollowingsLoaded _patchRow(
    FollowersAndFollowingsLoaded state,
    String id, {
    required bool isFollowingTab,
    required FollowProfileRow Function(FollowProfileRow row) patch,
  }) {
    if (isFollowingTab) {
      return state.copyWith(
        following: [
          for (final row in state.following)
            if (row.profileId == id) patch(row) else row,
        ],
      );
    }

    return state.copyWith(
      followers: [
        for (final row in state.followers)
          if (row.profileId == id) patch(row) else row,
      ],
    );
  }
}

sealed class FollowersAndFollowingsState {
  const FollowersAndFollowingsState();

  const factory FollowersAndFollowingsState.initial() = FollowersAndFollowingsInitial;
  const factory FollowersAndFollowingsState.loaded({
    required int tabIndex,
    required List<FollowProfileRow> following,
    required List<FollowProfileRow> followers,
    required bool followingLoading,
    required bool followersLoading,
    String? followingError,
    String? followersError,
  }) = FollowersAndFollowingsLoaded;
  const factory FollowersAndFollowingsState.error(String message) = FollowersAndFollowingsError;
}

final class FollowersAndFollowingsInitial extends FollowersAndFollowingsState {
  const FollowersAndFollowingsInitial();
}

final class FollowersAndFollowingsLoaded extends FollowersAndFollowingsState {
  const FollowersAndFollowingsLoaded({
    required this.tabIndex,
    required this.following,
    required this.followers,
    required this.followingLoading,
    required this.followersLoading,
    this.followingError,
    this.followersError,
  });

  final int tabIndex;
  final List<FollowProfileRow> following;
  final List<FollowProfileRow> followers;
  final bool followingLoading;
  final bool followersLoading;
  final String? followingError;
  final String? followersError;

  FollowersAndFollowingsLoaded copyWith({
    int? tabIndex,
    List<FollowProfileRow>? following,
    List<FollowProfileRow>? followers,
    bool? followingLoading,
    bool? followersLoading,
    String? followingError,
    String? followersError,
    bool clearFollowingError = false,
    bool clearFollowersError = false,
  }) {
    return FollowersAndFollowingsLoaded(
      tabIndex: tabIndex ?? this.tabIndex,
      following: following ?? this.following,
      followers: followers ?? this.followers,
      followingLoading: followingLoading ?? this.followingLoading,
      followersLoading: followersLoading ?? this.followersLoading,
      followingError: clearFollowingError ? null : (followingError ?? this.followingError),
      followersError: clearFollowersError ? null : (followersError ?? this.followersError),
    );
  }
}

final class FollowersAndFollowingsError extends FollowersAndFollowingsState {
  const FollowersAndFollowingsError(this.message);
  final String message;
}
