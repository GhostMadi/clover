import 'package:clover/core/session/app_session.dart';
import 'package:clover/feature/_attendance_/shared/data/attendance_context_store.dart';
import 'package:clover/feature/_attendance_/shared/data/attendance_local_cache.dart';
import 'package:clover/feature/_attendance_/shared/data/attendance_remote_repository.dart';
import 'package:clover/feature/_attendance_/shared/data/attendance_workplaces_prefs.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_snapshot.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_workplace.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

@injectable
class AttendanceHubCubit extends Cubit<AttendanceHubState> {
  AttendanceHubCubit(
    this._store,
    this._remote,
    this._cache,
    this._prefs,
    this._session,
  ) : super(const AttendanceHubState.initial()) {
    _store.snapshot.addListener(_onSnapshot);
  }

  final AttendanceContextStore _store;
  final AttendanceRemoteRepository _remote;
  final AttendanceLocalCache _cache;
  final AttendanceWorkplacesPrefs _prefs;
  final AppSession _session;

  @override
  Future<void> close() {
    _store.snapshot.removeListener(_onSnapshot);
    return super.close();
  }

  void _onSnapshot() {
    if (isClosed) return;
    final snap = _store.snapshot.value;
    if (snap == null) return;
    if (state is! AttendanceHubLoaded && state is! AttendanceHubLoading) return;
    emit(
      AttendanceHubState.loaded(
        snapshot: snap,
        adminWorkplaces: snap.workplaces.where((w) => w.isAdmin).toList(growable: false),
        isFromCache: false,
        isRefreshing: false,
      ),
    );
  }

  Future<void> load() async {
    if (isClosed) return;

    final uid = _session.userId;
    final memory = _store.snapshot.value;
    if (memory != null && _snapshotHasAdmin(memory)) {
      emit(
        AttendanceHubState.loaded(
          snapshot: memory,
          adminWorkplaces: memory.workplaces.where((w) => w.isAdmin).toList(growable: false),
          isFromCache: false,
          isRefreshing: true,
        ),
      );
      await _syncRemote();
      return;
    }

    if (uid != null && uid.isNotEmpty) {
      final cachedWp = await _cache.readWorkplaces(uid);
      final cachedFolders = await _cache.readFolders(uid);
      if (!isClosed && cachedWp != null) {
        final snap = AttendanceSnapshot(
          workplaces: cachedWp,
          folders: cachedFolders ?? const [],
          fromRemote: false,
        );
        emit(
          AttendanceHubState.loaded(
            snapshot: snap,
            adminWorkplaces: cachedWp.where((w) => w.isAdmin).toList(growable: false),
            isFromCache: true,
            isRefreshing: true,
          ),
        );
      } else if (!isClosed) {
        emit(const AttendanceHubState.loading());
      }
    } else if (!isClosed) {
      emit(const AttendanceHubState.loading());
    }

    await _syncRemote();
  }

  Future<void> refresh() => _syncRemote(keepRefreshing: true);

  Future<void> _syncRemote({bool keepRefreshing = false}) async {
    final prev = state is AttendanceHubLoaded ? state as AttendanceHubLoaded : null;
    if (keepRefreshing && prev != null && !isClosed) {
      emit(prev.copyWith(isRefreshing: true));
    }

    try {
      // Один bootstrap: store уже мог подтянуть дашборд; force+flush давал дубль.
      if (_store.isRemote && _store.snapshot.value != null) {
        await _store.refreshRemote();
      } else {
        await _store.hydrateCurrent();
      }
      if (isClosed) return;
      final snap = _store.snapshot.value ?? AttendanceSnapshot(fromRemote: true);
      emit(
        AttendanceHubState.loaded(
          snapshot: snap,
          adminWorkplaces: snap.workplaces.where((w) => w.isAdmin).toList(growable: false),
          isFromCache: false,
          isRefreshing: false,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      if (prev != null) {
        emit(prev.copyWith(isRefreshing: false));
        return;
      }
      emit(AttendanceHubState.error('$e'));
    }
  }

  Future<void> remember(String workplaceId) => _prefs.writeLastWorkplaceId(workplaceId);

  Future<bool> createWorkplace({
    required String name,
    String? folderId,
    double? lat,
    double? lng,
    int geofenceRadiusM = 150,
  }) async {
    if (!_store.isRemote) return false;
    try {
      await _remote.createWorkplace(
        name: name,
        folderId: folderId,
        lat: lat,
        lng: lng,
        geofenceRadiusM: geofenceRadiusM,
      );
      await _store.refreshRemote();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> createFolder(String name) async {
    if (!_store.isRemote) return false;
    try {
      await _remote.createFolder(name);
      await _store.refreshRemote();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> moveWorkplaceToFolder({
    required String workplaceId,
    String? folderId,
  }) async {
    if (!_store.isRemote) return false;
    try {
      await _remote.setWorkplaceFolder(workplaceId: workplaceId, folderId: folderId);
      await _store.refreshRemote();
      return true;
    } catch (_) {
      return false;
    }
  }

  static bool _snapshotHasAdmin(AttendanceSnapshot s) => s.workplaces.any((w) => w.isAdmin);
}

sealed class AttendanceHubState {
  const AttendanceHubState();

  const factory AttendanceHubState.initial() = AttendanceHubInitial;
  const factory AttendanceHubState.loading() = AttendanceHubLoading;
  const factory AttendanceHubState.loaded({
    required AttendanceSnapshot snapshot,
    required List<AttendanceWorkplace> adminWorkplaces,
    bool isFromCache,
    bool isRefreshing,
  }) = AttendanceHubLoaded;
  const factory AttendanceHubState.error(String message) = AttendanceHubError;
}

final class AttendanceHubInitial extends AttendanceHubState {
  const AttendanceHubInitial();
}

final class AttendanceHubLoading extends AttendanceHubState {
  const AttendanceHubLoading();
}

final class AttendanceHubLoaded extends AttendanceHubState {
  const AttendanceHubLoaded({
    required this.snapshot,
    required this.adminWorkplaces,
    this.isFromCache = false,
    this.isRefreshing = false,
  });

  final AttendanceSnapshot snapshot;
  final List<AttendanceWorkplace> adminWorkplaces;
  final bool isFromCache;
  final bool isRefreshing;

  AttendanceHubLoaded copyWith({
    AttendanceSnapshot? snapshot,
    List<AttendanceWorkplace>? adminWorkplaces,
    bool? isFromCache,
    bool? isRefreshing,
  }) {
    return AttendanceHubLoaded(
      snapshot: snapshot ?? this.snapshot,
      adminWorkplaces: adminWorkplaces ?? this.adminWorkplaces,
      isFromCache: isFromCache ?? this.isFromCache,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }
}

final class AttendanceHubError extends AttendanceHubState {
  const AttendanceHubError(this.message);

  final String message;
}
