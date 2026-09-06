import 'package:clover/feature/_attendance_/shared/data/attendance_context_store.dart';
import 'package:clover/feature/_attendance_/shared/data/attendance_remote_repository.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_snapshot.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_workplace.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

@injectable
class AttendanceHubCubit extends Cubit<AttendanceHubState> {
  AttendanceHubCubit(this._store, this._remote) : super(const AttendanceHubState.initial()) {
    _store.snapshot.addListener(_onSnapshot);
  }

  final AttendanceContextStore _store;
  final AttendanceRemoteRepository _remote;

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
      ),
    );
  }

  Future<void> load() async {
    if (isClosed) return;
    emit(const AttendanceHubState.loading());
    try {
      await _store.hydrateCurrent(force: true);
      if (isClosed) return;
      final snap = _store.snapshot.value ?? AttendanceSnapshot(fromRemote: true);
      emit(
        AttendanceHubState.loaded(
          snapshot: snap,
          adminWorkplaces: snap.workplaces.where((w) => w.isAdmin).toList(growable: false),
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(AttendanceHubState.error('$e'));
    }
  }

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
}

sealed class AttendanceHubState {
  const AttendanceHubState();

  const factory AttendanceHubState.initial() = AttendanceHubInitial;
  const factory AttendanceHubState.loading() = AttendanceHubLoading;
  const factory AttendanceHubState.loaded({
    required AttendanceSnapshot snapshot,
    required List<AttendanceWorkplace> adminWorkplaces,
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
  });

  final AttendanceSnapshot snapshot;
  final List<AttendanceWorkplace> adminWorkplaces;
}

final class AttendanceHubError extends AttendanceHubState {
  const AttendanceHubError(this.message);

  final String message;
}
