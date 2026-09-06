import 'package:clover/feature/_attendance_/shared/data/attendance_context_store.dart';
import 'package:clover/feature/_attendance_/shared/data/attendance_error.dart';
import 'package:clover/feature/_attendance_/shared/data/attendance_outbox.dart';
import 'package:clover/feature/_attendance_/shared/data/attendance_remote_repository.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_custom_punch_config.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_day_time.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_duty_roster.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_payroll_models.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_snapshot.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_workplace.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

@injectable
class AttendanceWorkplaceSettingsCubit extends Cubit<AttendanceWorkplaceSettingsState> {
  AttendanceWorkplaceSettingsCubit(this._store, this._remote, this._outbox)
      : super(const AttendanceWorkplaceSettingsState.initial()) {
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
    final snap = _store.snapshot.value;
    final workplace = snap?.workplaceById(workplaceId);
    if (snap == null || workplace == null) {
      emit(const AttendanceWorkplaceSettingsState.missing());
      return;
    }
    emit(
      AttendanceWorkplaceSettingsState.ready(
        workplaceId: workplaceId,
        snapshot: snap,
        workplace: workplace,
      ),
    );
  }

  Future<AttendancePersistResult> updateGeofence({
    required double latitude,
    required double longitude,
    required int geofenceRadiusM,
  }) async {
    final workplaceId = _workplaceId;
    if (workplaceId == null) return AttendancePersistResult.synced;

    void optimistic() {
      _store.patch((s) {
        final workplaces = s.workplaces.map((w) {
          if (w.id != workplaceId) return w;
          return w.copyWith(latitude: latitude, longitude: longitude, geofenceRadiusM: geofenceRadiusM);
        }).toList(growable: false);
        return s.copyWith(workplaces: workplaces);
      });
    }

    if (!_store.isRemote) {
      optimistic();
      return AttendancePersistResult.synced;
    }

    try {
      await _remote.updateWorkplaceSettings(
        workplaceId: workplaceId,
        lat: latitude,
        lng: longitude,
        geofenceRadiusM: geofenceRadiusM,
      );
      await _store.refreshRemote();
      return AttendancePersistResult.synced;
    } on AttendanceException catch (e) {
      if (!e.isRetriableNetwork) rethrow;
      optimistic();
      await _outbox.enqueue(
        AttendanceOutboxItem(
          id: 'geofence_$workplaceId',
          kind: AttendanceOutboxKind.geofence,
          payload: {
            'workplace_id': workplaceId,
            'lat': latitude,
            'lng': longitude,
            'geofence_radius_m': geofenceRadiusM,
          },
          createdAt: DateTime.now().toUtc(),
        ),
      );
      return AttendancePersistResult.queued;
    }
  }

  Future<AttendancePersistResult> updatePunchConfig({
    required bool clockInEnabled,
    required bool clockOutEnabled,
    AttendanceDayTime? clockInScheduledTime,
    AttendanceDayTime? clockOutScheduledTime,
    bool clearClockInScheduledTime = false,
    bool clearClockOutScheduledTime = false,
    required List<AttendanceCustomPunchConfig> customPunches,
  }) async {
    final workplaceId = _workplaceId;
    if (workplaceId == null) return AttendancePersistResult.synced;

    String? fmt(AttendanceDayTime? t) =>
        t == null ? null : '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';

    void optimistic() {
      _store.patch((s) {
        final workplaces = s.workplaces.map((w) {
          if (w.id != workplaceId) return w;
          return w.copyWith(
            clockInEnabled: clockInEnabled,
            clockOutEnabled: clockOutEnabled,
            clockInScheduledTime: clockInScheduledTime,
            clockOutScheduledTime: clockOutScheduledTime,
            clearClockInScheduledTime: clearClockInScheduledTime,
            clearClockOutScheduledTime: clearClockOutScheduledTime,
            customPunches: customPunches,
          );
        }).toList(growable: false);
        return s.copyWith(workplaces: workplaces);
      });
    }

    if (!_store.isRemote) {
      optimistic();
      return AttendancePersistResult.synced;
    }

    final clockInScheduled = clearClockInScheduledTime ? null : fmt(clockInScheduledTime);
    final clockOutScheduled = clearClockOutScheduledTime ? null : fmt(clockOutScheduledTime);

    try {
      await _remote.updateWorkplaceSettings(
        workplaceId: workplaceId,
        clockInEnabled: clockInEnabled,
        clockOutEnabled: clockOutEnabled,
        clockInScheduled: clockInScheduled,
        clockOutScheduled: clockOutScheduled,
      );
      await _remote.replaceCustomPunchTypes(workplaceId: workplaceId, customPunches: customPunches);
      await _store.refreshRemote();
      return AttendancePersistResult.synced;
    } on AttendanceException catch (e) {
      if (!e.isRetriableNetwork) rethrow;
      optimistic();
      await _outbox.enqueue(
        AttendanceOutboxItem(
          id: 'punch_cfg_$workplaceId',
          kind: AttendanceOutboxKind.punchConfig,
          payload: {
            'workplace_id': workplaceId,
            'clock_in_enabled': clockInEnabled,
            'clock_out_enabled': clockOutEnabled,
            'clock_in_scheduled': clockInScheduled,
            'clock_out_scheduled': clockOutScheduled,
            'custom_punches': [
              for (final c in customPunches)
                {
                  'id': c.id,
                  'label': c.label,
                  'scheduled': fmt(c.scheduledTime),
                },
            ],
          },
          createdAt: DateTime.now().toUtc(),
        ),
      );
      return AttendancePersistResult.queued;
    }
  }

  Future<AttendancePersistResult> updatePayrollRules(AttendancePayrollRules rules) async {
    final workplaceId = _workplaceId;
    if (workplaceId == null) return AttendancePersistResult.synced;

    void optimistic() {
      _store.patch((s) {
        final workplaces = s.workplaces.map((w) {
          if (w.id != workplaceId) return w;
          return w.copyWith(payrollRules: rules);
        }).toList(growable: false);
        return s.copyWith(workplaces: workplaces);
      });
    }

    if (!_store.isRemote) {
      optimistic();
      return AttendancePersistResult.synced;
    }

    try {
      await _remote.updatePayrollSettings(workplaceId: workplaceId, payrollRules: rules.toJson());
      await _store.refreshRemote();
      return AttendancePersistResult.synced;
    } on AttendanceException catch (e) {
      if (!e.isRetriableNetwork) rethrow;
      optimistic();
      await _outbox.enqueue(
        AttendanceOutboxItem(
          id: 'payroll_$workplaceId',
          kind: AttendanceOutboxKind.payrollSettings,
          payload: {'workplace_id': workplaceId, 'payroll_rules': rules.toJson()},
          createdAt: DateTime.now().toUtc(),
        ),
      );
      return AttendancePersistResult.queued;
    }
  }

  Future<AttendancePersistResult> updateWorkerBaseSalary({
    required String workerId,
    required int baseSalary,
  }) async {
    final workplaceId = _workplaceId;
    if (workplaceId == null) return AttendancePersistResult.synced;

    void optimistic() {
      _store.patch((s) {
        final workplaces = s.workplaces.map((w) {
          if (w.id != workplaceId) return w;
          final salaries = Map<String, int>.from(w.workerBaseSalaries);
          salaries[workerId] = baseSalary;
          return w.copyWith(workerBaseSalaries: salaries);
        }).toList(growable: false);
        return s.copyWith(workplaces: workplaces);
      });
    }

    if (!_store.isRemote) {
      optimistic();
      return AttendancePersistResult.synced;
    }

    try {
      await _remote.setMemberBaseSalary(
        workplaceId: workplaceId,
        profileId: workerId,
        baseSalaryTenge: baseSalary,
      );
      await _store.refreshRemote();
      return AttendancePersistResult.synced;
    } on AttendanceException catch (e) {
      if (!e.isRetriableNetwork) rethrow;
      optimistic();
      await _outbox.enqueue(
        AttendanceOutboxItem(
          id: 'salary_${workplaceId}_$workerId',
          kind: AttendanceOutboxKind.memberBaseSalary,
          payload: {
            'workplace_id': workplaceId,
            'profile_id': workerId,
            'base_salary_tenge': baseSalary,
          },
          createdAt: DateTime.now().toUtc(),
        ),
      );
      return AttendancePersistResult.queued;
    }
  }

  Future<AttendancePersistResult> updateDutyRoster(AttendanceDutyRoster roster) async {
    final workplaceId = _workplaceId;
    if (workplaceId == null) return AttendancePersistResult.synced;

    void optimistic() {
      _store.patch((s) {
        final workplaces = s.workplaces.map((w) {
          if (w.id != workplaceId) return w;
          return w.copyWith(dutyRoster: roster);
        }).toList(growable: false);
        return s.copyWith(workplaces: workplaces);
      });
    }

    if (!_store.isRemote) {
      optimistic();
      return AttendancePersistResult.synced;
    }

    try {
      await _remote.updateDutyRoster(workplaceId: workplaceId, dutyRoster: roster.toJson());
      await _store.refreshRemote();
      return AttendancePersistResult.synced;
    } on AttendanceException catch (e) {
      if (!e.isRetriableNetwork) rethrow;
      optimistic();
      await _outbox.enqueue(
        AttendanceOutboxItem(
          id: 'duty_$workplaceId',
          kind: AttendanceOutboxKind.dutyRoster,
          payload: {'workplace_id': workplaceId, 'duty_roster': roster.toJson()},
          createdAt: DateTime.now().toUtc(),
        ),
      );
      return AttendancePersistResult.queued;
    }
  }

  Future<AttendancePersistResult> setDutyOnlyPunch(bool value) async {
    final workplaceId = _workplaceId;
    if (workplaceId == null) return AttendancePersistResult.synced;

    void optimistic() {
      _store.patch((s) {
        final workplaces = s.workplaces.map((w) {
          if (w.id != workplaceId) return w;
          return w.copyWith(dutyOnlyPunch: value);
        }).toList(growable: false);
        return s.copyWith(workplaces: workplaces);
      });
    }

    if (!_store.isRemote) {
      optimistic();
      return AttendancePersistResult.synced;
    }

    try {
      await _remote.setDutyOnlyPunch(workplaceId: workplaceId, dutyOnlyPunch: value);
      await _store.refreshRemote();
      return AttendancePersistResult.synced;
    } on AttendanceException catch (e) {
      if (!e.isRetriableNetwork) rethrow;
      optimistic();
      return AttendancePersistResult.queued;
    }
  }
}

sealed class AttendanceWorkplaceSettingsState {
  const AttendanceWorkplaceSettingsState();

  const factory AttendanceWorkplaceSettingsState.initial() = AttendanceWorkplaceSettingsInitial;
  const factory AttendanceWorkplaceSettingsState.missing() = AttendanceWorkplaceSettingsMissing;
  const factory AttendanceWorkplaceSettingsState.ready({
    required String workplaceId,
    required AttendanceSnapshot snapshot,
    required AttendanceWorkplace workplace,
  }) = AttendanceWorkplaceSettingsReady;
}

final class AttendanceWorkplaceSettingsInitial extends AttendanceWorkplaceSettingsState {
  const AttendanceWorkplaceSettingsInitial();
}

final class AttendanceWorkplaceSettingsMissing extends AttendanceWorkplaceSettingsState {
  const AttendanceWorkplaceSettingsMissing();
}

final class AttendanceWorkplaceSettingsReady extends AttendanceWorkplaceSettingsState {
  const AttendanceWorkplaceSettingsReady({
    required this.workplaceId,
    required this.snapshot,
    required this.workplace,
  });

  final String workplaceId;
  final AttendanceSnapshot snapshot;
  final AttendanceWorkplace workplace;
}
