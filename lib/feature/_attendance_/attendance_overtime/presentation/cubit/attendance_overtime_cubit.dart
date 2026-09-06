import 'package:clover/feature/_attendance_/shared/data/attendance_context_store.dart';
import 'package:clover/feature/_attendance_/shared/data/attendance_error.dart';
import 'package:clover/feature/_attendance_/shared/data/attendance_outbox.dart';
import 'package:clover/feature/_attendance_/shared/data/attendance_remote_repository.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_overtime_entry.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_snapshot.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

@injectable
class AttendanceOvertimeCubit extends Cubit<AttendanceOvertimeState> {
  AttendanceOvertimeCubit(this._store, this._remote, this._outbox)
      : super(const AttendanceOvertimeState.initial()) {
    _store.snapshot.addListener(_onSnapshot);
  }

  final AttendanceContextStore _store;
  final AttendanceRemoteRepository _remote;
  final AttendanceOutbox _outbox;

  String? _workplaceId;

  @override
  Future<void> close() {
    _store.snapshot.removeListener(_onSnapshot);
    return super.close();
  }

  void bind(String workplaceId) {
    _workplaceId = workplaceId;
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
    final entries = snap.overtimeEntries.where((e) => e.workplaceId == workplaceId).toList(growable: false);
    emit(AttendanceOvertimeState.loaded(workplaceId: workplaceId, snapshot: snap, entries: entries));
  }

  Future<AttendancePersistResult> addOvertimeRequest(AttendanceOvertimeEntry entry) async {
    void optimistic() {
      _store.patch((s) => s.copyWith(overtimeEntries: [...s.overtimeEntries, entry]));
    }

    if (!_store.isRemote) {
      optimistic();
      return AttendancePersistResult.synced;
    }

    final clientRequestId = entry.id.startsWith('ot_') ? entry.id : 'ot_${entry.id}';
    final profileId = entry.workerId.isNotEmpty ? entry.workerId : _store.selfWorkerId();

    try {
      await _remote.upsertOvertime(
        workplaceId: entry.workplaceId,
        profileId: profileId,
        workDate: entry.date,
        hours: entry.hours,
        clientRequestId: clientRequestId,
      );
      await _store.refreshRemote();
      return AttendancePersistResult.synced;
    } on AttendanceException catch (e) {
      if (!e.isRetriableNetwork) rethrow;
      optimistic();
      await _outbox.enqueue(
        AttendanceOutboxItem(
          id: 'ot_upsert_$clientRequestId',
          kind: AttendanceOutboxKind.overtimeUpsert,
          payload: {
            'workplace_id': entry.workplaceId,
            'profile_id': profileId,
            'work_date': entry.date.toIso8601String(),
            'hours': entry.hours,
            'client_request_id': clientRequestId,
          },
          createdAt: DateTime.now().toUtc(),
        ),
      );
      return AttendancePersistResult.queued;
    }
  }

  Future<AttendancePersistResult> setOvertimeStatus({
    required String entryId,
    required AttendanceOvertimeStatus status,
  }) async {
    void optimistic() {
      _store.patch((s) {
        final entries = s.overtimeEntries.map((e) {
          if (e.id != entryId) return e;
          return e.copyWith(status: status);
        }).toList(growable: false);
        return s.copyWith(overtimeEntries: entries);
      });
    }

    if (!_store.isRemote) {
      optimistic();
      return AttendancePersistResult.synced;
    }

    try {
      await _remote.setOvertimeStatus(entryId: entryId, status: status.key);
      await _store.refreshRemote();
      return AttendancePersistResult.synced;
    } on AttendanceException catch (e) {
      if (!e.isRetriableNetwork) rethrow;
      optimistic();
      await _outbox.enqueue(
        AttendanceOutboxItem(
          id: 'ot_status_$entryId',
          kind: AttendanceOutboxKind.overtimeStatus,
          payload: {'entry_id': entryId, 'status': status.key},
          createdAt: DateTime.now().toUtc(),
        ),
      );
      return AttendancePersistResult.queued;
    }
  }
}

sealed class AttendanceOvertimeState {
  const AttendanceOvertimeState();

  const factory AttendanceOvertimeState.initial() = AttendanceOvertimeInitial;
  const factory AttendanceOvertimeState.loaded({
    required String workplaceId,
    required AttendanceSnapshot snapshot,
    required List<AttendanceOvertimeEntry> entries,
  }) = AttendanceOvertimeLoaded;
}

final class AttendanceOvertimeInitial extends AttendanceOvertimeState {
  const AttendanceOvertimeInitial();
}

final class AttendanceOvertimeLoaded extends AttendanceOvertimeState {
  const AttendanceOvertimeLoaded({
    required this.workplaceId,
    required this.snapshot,
    required this.entries,
  });

  final String workplaceId;
  final AttendanceSnapshot snapshot;
  final List<AttendanceOvertimeEntry> entries;
}
