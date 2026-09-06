import 'package:clover/feature/_attendance_/shared/data/models/attendance_worker.dart';
import 'package:clover/feature/_attendance_/shared/data/attendance_context_store.dart';
import 'package:clover/feature/_attendance_/shared/data/attendance_error.dart';
import 'package:clover/feature/_attendance_/shared/data/attendance_outbox.dart';
import 'package:clover/feature/_attendance_/shared/data/attendance_remote_repository.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_absence.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_snapshot.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

@injectable
class AttendanceAbsencesCubit extends Cubit<AttendanceAbsencesState> {
  AttendanceAbsencesCubit(this._store, this._remote, this._outbox)
      : super(const AttendanceAbsencesState.initial()) {
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
    final absences = snap.absences.where((e) => e.workplaceId == workplaceId).toList()
      ..sort((a, b) => b.startDate.compareTo(a.startDate));
    final workers = snap.workersFor(workplaceId).where((w) => w.isAccepted).toList(growable: false);
    emit(
      AttendanceAbsencesState.loaded(
        workplaceId: workplaceId,
        snapshot: snap,
        absences: absences,
        workers: workers,
      ),
    );
  }

  Future<AttendancePersistResult> addAbsence(AttendanceAbsenceEntry entry) async {
    void optimistic() {
      _store.patch((s) => s.copyWith(absences: [...s.absences, entry]));
    }

    if (!_store.isRemote) {
      optimistic();
      return AttendancePersistResult.synced;
    }

    final absenceId = entry.id.startsWith('abs_') ? null : entry.id;
    try {
      await _remote.upsertAbsence(
        workplaceId: entry.workplaceId,
        profileId: entry.workerId,
        kind: entry.kind,
        startDate: entry.startDate,
        endDate: entry.endDate,
        note: entry.note,
        absenceId: absenceId,
      );
      await _store.refreshRemote();
      return AttendancePersistResult.synced;
    } on AttendanceException catch (e) {
      if (!e.isRetriableNetwork) rethrow;
      optimistic();
      await _outbox.enqueue(
        AttendanceOutboxItem(
          id: 'absence_${entry.id}',
          kind: AttendanceOutboxKind.absence,
          payload: {
            'workplace_id': entry.workplaceId,
            'profile_id': entry.workerId,
            'kind': entry.kind.key,
            'start_date': entry.startDate.toIso8601String(),
            'end_date': entry.endDate.toIso8601String(),
            'note': entry.note,
            'absence_id': absenceId,
          },
          createdAt: DateTime.now().toUtc(),
        ),
      );
      return AttendancePersistResult.queued;
    }
  }
}

sealed class AttendanceAbsencesState {
  const AttendanceAbsencesState();

  const factory AttendanceAbsencesState.initial() = AttendanceAbsencesInitial;
  const factory AttendanceAbsencesState.loaded({
    required String workplaceId,
    required AttendanceSnapshot snapshot,
    required List<AttendanceAbsenceEntry> absences,
    required List<AttendanceWorkerListItem> workers,
  }) = AttendanceAbsencesLoaded;
}

final class AttendanceAbsencesInitial extends AttendanceAbsencesState {
  const AttendanceAbsencesInitial();
}

final class AttendanceAbsencesLoaded extends AttendanceAbsencesState {
  const AttendanceAbsencesLoaded({
    required this.workplaceId,
    required this.snapshot,
    required this.absences,
    required this.workers,
  });

  final String workplaceId;
  final AttendanceSnapshot snapshot;
  final List<AttendanceAbsenceEntry> absences;
  final List<AttendanceWorkerListItem> workers;
}
