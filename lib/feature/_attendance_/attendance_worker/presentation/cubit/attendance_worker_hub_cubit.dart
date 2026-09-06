import 'package:clover/feature/_attendance_/shared/data/attendance_context_store.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_membership.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_snapshot.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

@injectable
class AttendanceWorkerHubCubit extends Cubit<AttendanceWorkerHubState> {
  AttendanceWorkerHubCubit(this._store) : super(const AttendanceWorkerHubState.initial()) {
    _store.snapshot.addListener(_onSnapshot);
  }

  final AttendanceContextStore _store;

  @override
  Future<void> close() {
    _store.snapshot.removeListener(_onSnapshot);
    return super.close();
  }

  void _onSnapshot() {
    if (isClosed) return;
    final snap = _store.snapshot.value;
    if (snap == null) return;
    if (state is! AttendanceWorkerHubLoaded && state is! AttendanceWorkerHubLoading) return;
    emit(
      AttendanceWorkerHubState.loaded(
        snapshot: snap,
        memberships: List<AttendanceMembership>.unmodifiable(snap.memberships),
      ),
    );
  }

  Future<void> load() async {
    if (isClosed) return;
    emit(const AttendanceWorkerHubState.loading());
    try {
      await _store.hydrateCurrent(force: true);
      if (isClosed) return;
      final snap = _store.snapshot.value ?? AttendanceSnapshot(fromRemote: true);
      emit(
        AttendanceWorkerHubState.loaded(
          snapshot: snap,
          memberships: List<AttendanceMembership>.unmodifiable(snap.memberships),
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(AttendanceWorkerHubState.error('$e'));
    }
  }
}

sealed class AttendanceWorkerHubState {
  const AttendanceWorkerHubState();

  const factory AttendanceWorkerHubState.initial() = AttendanceWorkerHubInitial;
  const factory AttendanceWorkerHubState.loading() = AttendanceWorkerHubLoading;
  const factory AttendanceWorkerHubState.loaded({
    required AttendanceSnapshot snapshot,
    required List<AttendanceMembership> memberships,
  }) = AttendanceWorkerHubLoaded;
  const factory AttendanceWorkerHubState.error(String message) = AttendanceWorkerHubError;
}

final class AttendanceWorkerHubInitial extends AttendanceWorkerHubState {
  const AttendanceWorkerHubInitial();
}

final class AttendanceWorkerHubLoading extends AttendanceWorkerHubState {
  const AttendanceWorkerHubLoading();
}

final class AttendanceWorkerHubLoaded extends AttendanceWorkerHubState {
  const AttendanceWorkerHubLoaded({
    required this.snapshot,
    required this.memberships,
  });

  final AttendanceSnapshot snapshot;
  final List<AttendanceMembership> memberships;
}

final class AttendanceWorkerHubError extends AttendanceWorkerHubState {
  const AttendanceWorkerHubError(this.message);

  final String message;
}
