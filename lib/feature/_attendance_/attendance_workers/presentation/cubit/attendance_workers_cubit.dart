import 'package:clover/feature/_attendance_/shared/data/models/attendance_worker.dart';
import 'package:clover/feature/_attendance_/shared/data/attendance_context_store.dart';
import 'package:clover/feature/_attendance_/shared/data/attendance_remote_repository.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_profile_hit.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_snapshot.dart';
import 'package:clover/feature/_chat_/chat/data/repository/chat_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

@injectable
class AttendanceWorkersCubit extends Cubit<AttendanceWorkersState> {
  AttendanceWorkersCubit(this._store, this._remote, this._chat)
      : super(const AttendanceWorkersState.initial()) {
    _store.snapshot.addListener(_onSnapshot);
  }

  final AttendanceContextStore _store;
  final AttendanceRemoteRepository _remote;
  final ChatRepository _chat;

  String? _workplaceId;

  @override
  Future<void> close() {
    _store.snapshot.removeListener(_onSnapshot);
    return super.close();
  }

  void bind(String workplaceId) {
    _workplaceId = workplaceId;
    final snap = _store.snapshot.value;
    if (snap != null) {
      emit(AttendanceWorkersState.loaded(workplaceId: workplaceId, snapshot: snap));
    } else {
      emit(
        AttendanceWorkersState.loaded(
          workplaceId: workplaceId,
          snapshot: AttendanceSnapshot(fromRemote: true),
        ),
      );
    }
  }

  void _onSnapshot() {
    if (isClosed) return;
    final workplaceId = _workplaceId;
    final snap = _store.snapshot.value;
    if (workplaceId == null || snap == null) return;
    emit(AttendanceWorkersState.loaded(workplaceId: workplaceId, snapshot: snap));
  }

  Future<List<AttendanceProfileHit>> searchProfiles(String query) {
    final workplaceId = _workplaceId;
    final existing = workplaceId == null
        ? const <String>{}
        : (_store.snapshot.value?.workersFor(workplaceId) ?? const <AttendanceWorkerListItem>[])
            .map((w) => w.id)
            .toSet();
    return _remote.searchProfiles(query, excludeProfileIds: existing);
  }

  Future<void> setWorkerStatus({
    required String workerId,
    required AttendanceWorkerInviteStatus status,
  }) async {
    final workplaceId = _workplaceId;
    if (workplaceId == null) return;

    if (_store.isRemote) {
      final m = _store.snapshot.value?.membershipForProfile(workplaceId: workplaceId, profileId: workerId);
      final mid = m?.id;
      if (mid == null) return;
      final Future<void> op = switch (status) {
        AttendanceWorkerInviteStatus.accepted => _remote.acceptInvite(mid),
        AttendanceWorkerInviteStatus.declined => _remote.rejectInvite(mid),
        AttendanceWorkerInviteStatus.archived => _remote.archiveMember(mid),
        AttendanceWorkerInviteStatus.pending => _remote.reinviteMember(mid),
      };
      await op;
      await _store.refreshRemote();
      return;
    }

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

  Future<AttendanceInviteDm?> sendChatInvite(AttendanceWorkerListItem candidate) async {
    final workplaceId = _workplaceId;
    if (workplaceId == null) return null;

    if (!_store.isRemote) {
      _store.patch((s) {
        var extras = s.extraWorkers;
        final inBase = s.workersFor(workplaceId).any((w) => w.id == candidate.id);
        final inExtras = extras.any((w) => w.id == candidate.id);
        if (!inBase && !inExtras) {
          extras = [...extras, candidate.copyWith(status: AttendanceWorkerInviteStatus.pending)];
        }

        final overrides = Map<String, Map<String, AttendanceWorkerInviteStatus>>.from(
          s.workerStatusOverrides.map((k, v) => MapEntry(k, Map<String, AttendanceWorkerInviteStatus>.from(v))),
        );
        final workplaceMap = Map<String, AttendanceWorkerInviteStatus>.from(overrides[workplaceId] ?? {});
        workplaceMap[candidate.id] = AttendanceWorkerInviteStatus.pending;
        overrides[workplaceId] = workplaceMap;

        return s.copyWith(
          extraWorkers: extras,
          workerStatusOverrides: overrides,
          mockUnreadAttendanceChat: true,
        );
      });
      return null;
    }

    final snap = _store.snapshot.value;
    final existing = snap?.membershipForProfile(workplaceId: workplaceId, profileId: candidate.id);
    final mid = existing?.id;

    if (mid != null &&
        (existing!.status == AttendanceWorkerInviteStatus.archived ||
            existing.status == AttendanceWorkerInviteStatus.declined)) {
      await _remote.reinviteMember(mid);
    } else if (existing == null || existing.status != AttendanceWorkerInviteStatus.pending) {
      await _remote.inviteMember(workplaceId: workplaceId, profileId: candidate.id);
    }

    final conversationId = await _chat.createDm(candidate.id);
    // Invite RPC уже шлёт CLOVER_CARD в DM + notification.
    await _store.refreshRemote();

    final username = candidate.username.trim().isEmpty ? candidate.displayName : candidate.username;
    return AttendanceInviteDm(
      conversationId: conversationId,
      otherUserId: candidate.id,
      username: username,
    );
  }
}

sealed class AttendanceWorkersState {
  const AttendanceWorkersState();

  const factory AttendanceWorkersState.initial() = AttendanceWorkersInitial;
  const factory AttendanceWorkersState.loaded({
    required String workplaceId,
    required AttendanceSnapshot snapshot,
  }) = AttendanceWorkersLoaded;
}

final class AttendanceWorkersInitial extends AttendanceWorkersState {
  const AttendanceWorkersInitial();
}

final class AttendanceWorkersLoaded extends AttendanceWorkersState {
  const AttendanceWorkersLoaded({
    required this.workplaceId,
    required this.snapshot,
  });

  final String workplaceId;
  final AttendanceSnapshot snapshot;
}
