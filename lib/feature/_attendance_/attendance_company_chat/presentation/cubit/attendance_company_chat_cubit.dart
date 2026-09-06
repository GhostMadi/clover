import 'package:clover/feature/_attendance_/shared/data/models/attendance_worker.dart';
import 'package:clover/feature/_attendance_/shared/data/attendance_context_store.dart';
import 'package:clover/feature/_attendance_/shared/data/attendance_remote_repository.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_membership.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_snapshot.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_workplace.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

@injectable
class AttendanceCompanyChatCubit extends Cubit<AttendanceCompanyChatState> {
  AttendanceCompanyChatCubit(this._store, this._remote) : super(const AttendanceCompanyChatState.initial()) {
    _store.snapshot.addListener(_onSnapshot);
  }

  final AttendanceContextStore _store;
  final AttendanceRemoteRepository _remote;

  String? _workplaceId;

  @override
  Future<void> close() {
    _store.snapshot.removeListener(_onSnapshot);
    return super.close();
  }

  void bind(String workplaceId) {
    _workplaceId = workplaceId;
    _store.clearUnreadChat();
    _emitFromStore();
  }

  void _onSnapshot() {
    if (isClosed) return;
    _emitFromStore();
  }

  void _emitFromStore() {
    final workplaceId = _workplaceId;
    if (workplaceId == null) return;
    final snap = _store.snapshot.value ?? AttendanceSnapshot(fromRemote: true);
    final workplace = snap.workplaceById(workplaceId);
    final pending = snap.workersFor(workplaceId).where((w) => w.isPending).toList(growable: false);
    final membership = snap.membershipByWorkplace(workplaceId);
    emit(
      AttendanceCompanyChatState.loaded(
        workplaceId: workplaceId,
        snapshot: snap,
        workplace: workplace,
        pendingWorkers: pending,
        membership: membership,
      ),
    );
  }

  Future<void> acceptInvite(String workerId) async {
    final workplaceId = _workplaceId;
    if (workplaceId == null) return;

    if (_store.isRemote) {
      final m = _store.snapshot.value?.membershipForProfile(workplaceId: workplaceId, profileId: workerId);
      final mid = m?.id;
      if (mid == null) return;
      await _remote.acceptInvite(mid);
      await _store.refreshRemote();
      return;
    }

    _setWorkerStatus(workerId: workerId, status: AttendanceWorkerInviteStatus.accepted);
    _store.clearUnreadChat();
  }

  Future<void> rejectInvite(String workerId) async {
    final workplaceId = _workplaceId;
    if (workplaceId == null) return;

    if (_store.isRemote) {
      final m = _store.snapshot.value?.membershipForProfile(workplaceId: workplaceId, profileId: workerId);
      final mid = m?.id;
      if (mid == null) return;
      await _remote.rejectInvite(mid);
      await _store.refreshRemote();
      return;
    }

    _setWorkerStatus(workerId: workerId, status: AttendanceWorkerInviteStatus.declined);
    _store.clearUnreadChat();
  }

  Future<void> ackConfig() async {
    final workplaceId = _workplaceId;
    if (workplaceId == null) return;

    if (_store.isRemote) {
      await _remote.ackConfig(workplaceId);
      await _store.refreshRemote();
      return;
    }

    _store.patch((s) {
      final memberships = s.memberships.map((m) {
        if (m.workplaceId != workplaceId) return m;
        return m.copyWith(ackVersion: m.configVersion);
      }).toList(growable: false);
      return s.copyWith(memberships: memberships);
    });
  }

  void _setWorkerStatus({
    required String workerId,
    required AttendanceWorkerInviteStatus status,
  }) {
    final workplaceId = _workplaceId;
    if (workplaceId == null) return;
    _store.patch((s) {
      final overrides = Map<String, Map<String, AttendanceWorkerInviteStatus>>.from(
        s.workerStatusOverrides.map((k, v) => MapEntry(k, Map<String, AttendanceWorkerInviteStatus>.from(v))),
      );
      final workplaceMap = Map<String, AttendanceWorkerInviteStatus>.from(overrides[workplaceId] ?? {});
      workplaceMap[workerId] = status;
      overrides[workplaceId] = workplaceMap;
      return s.copyWith(workerStatusOverrides: overrides);
    });
  }
}

sealed class AttendanceCompanyChatState {
  const AttendanceCompanyChatState();

  const factory AttendanceCompanyChatState.initial() = AttendanceCompanyChatInitial;
  const factory AttendanceCompanyChatState.loaded({
    required String workplaceId,
    required AttendanceSnapshot snapshot,
    AttendanceWorkplace? workplace,
    required List<AttendanceWorkerListItem> pendingWorkers,
    AttendanceMembership? membership,
  }) = AttendanceCompanyChatLoaded;
}

final class AttendanceCompanyChatInitial extends AttendanceCompanyChatState {
  const AttendanceCompanyChatInitial();
}

final class AttendanceCompanyChatLoaded extends AttendanceCompanyChatState {
  const AttendanceCompanyChatLoaded({
    required this.workplaceId,
    required this.snapshot,
    required this.pendingWorkers,
    this.workplace,
    this.membership,
  });

  final String workplaceId;
  final AttendanceSnapshot snapshot;
  final AttendanceWorkplace? workplace;
  final List<AttendanceWorkerListItem> pendingWorkers;
  final AttendanceMembership? membership;
}
