import 'package:clover/feature/_attendance_/shared/data/attendance_context_store.dart';
import 'package:clover/feature/_attendance_/shared/data/attendance_error.dart';
import 'package:clover/feature/_attendance_/shared/data/attendance_location.dart';
import 'package:clover/feature/_attendance_/shared/data/attendance_outbox.dart';
import 'package:clover/feature/_attendance_/shared/data/attendance_remote_repository.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_custom_punch_config.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_membership.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_punch_record.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_punch_type.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_snapshot.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_workplace.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

@injectable
class AttendancePunchCubit extends Cubit<AttendancePunchState> {
  AttendancePunchCubit(this._store, this._remote, this._outbox) : super(const AttendancePunchState.initial()) {
    _store.snapshot.addListener(_onSnapshot);
  }

  final AttendanceContextStore _store;
  final AttendanceRemoteRepository _remote;
  final AttendanceOutbox _outbox;

  String? _workplaceId;
  int _punchSeq = 0;

  bool _gpsOn = false;
  bool _inZone = false;
  bool _locating = false;
  double? _lat;
  double? _lng;

  @override
  Future<void> close() {
    _store.snapshot.removeListener(_onSnapshot);
    return super.close();
  }

  void bind(String workplaceId) {
    _workplaceId = workplaceId;
    _emitFromStore();
    // ignore: discarded_futures
    refreshLocation();
  }

  void _onSnapshot() {
    if (isClosed) return;
    _emitFromStore();
  }

  void _emitFromStore() {
    final workplaceId = _workplaceId;
    if (workplaceId == null) return;
    final snap = _store.snapshot.value;
    if (snap == null) {
      emit(const AttendancePunchState.missing());
      return;
    }
    final workplace = snap.workplaceById(workplaceId);
    final membership = snap.membershipByWorkplace(workplaceId);
    if (workplace == null || membership == null) {
      emit(const AttendancePunchState.missing());
      return;
    }
    final workerId = membership.profileId ?? _store.selfWorkerId();

    final gpsOn = _store.isRemote ? _gpsOn : snap.mockGpsEnabled;
    final inZone = _store.isRemote ? _inZone : snap.mockInGeofence;

    emit(
      AttendancePunchState.ready(
        workplaceId: workplaceId,
        snapshot: snap,
        workplace: workplace,
        membership: membership,
        workerId: workerId,
        isRemote: _store.isRemote,
        history: snap.punchHistoryFor(
          workplaceId: workplaceId,
          workerId: workerId,
          includeCancelled: true,
        ),
        gpsOn: gpsOn,
        inZone: inZone,
        locating: _locating,
      ),
    );
  }

  Future<void> refreshLocation() async {
    final workplaceId = _workplaceId;
    if (workplaceId == null) return;

    if (!_store.isRemote) {
      final snap = _store.snapshot.value;
      _gpsOn = snap?.mockGpsEnabled ?? false;
      _inZone = snap?.mockInGeofence ?? false;
      _locating = false;
      _emitFromStore();
      return;
    }

    _locating = true;
    _emitFromStore();

    final workplace = _store.snapshot.value?.workplaceById(workplaceId);
    final (result, loc) = await AttendanceLocation.current();

    if (result == AttendanceLocationResult.ok && loc != null) {
      _gpsOn = true;
      _lat = loc.latitude;
      _lng = loc.longitude;
      if (workplace != null && workplace.hasGeofenceCenter) {
        _inZone = AttendanceLocation.inGeofence(
          deviceLat: loc.latitude,
          deviceLng: loc.longitude,
          centerLat: workplace.latitude!,
          centerLng: workplace.longitude!,
          radiusM: workplace.geofenceRadiusM,
        );
      } else {
        _inZone = true;
      }
    } else {
      _gpsOn = false;
      _inZone = false;
      _lat = null;
      _lng = null;
    }

    _locating = false;
    if (!isClosed) _emitFromStore();
  }

  /// Last location error hint for UI snackbars (after refresh / punch).
  AttendanceLocationResult? lastLocationError;
  AttendanceException? lastPunchError;

  Future<bool> punch(AttendancePunchType type, {double? lat, double? lng}) async {
    final workplaceId = _workplaceId;
    if (workplaceId == null) return false;
    final resolvedWorkerId = _store.selfWorkerId();
    lastLocationError = null;
    lastPunchError = null;

    final snap = _store.snapshot.value;
    final membership = snap?.memberships.where((m) => m.workplaceId == workplaceId).firstOrNull;
    if (type.isClockIn && membership?.shiftOpen == true) {
      throw const AttendanceException(
        AttendanceErrorCode.invalidPunch,
        'Смена уже открыта — сначала отметьте «Ушёл»',
      );
    }

    try {
      if (_store.isRemote) {
        var useLat = lat ?? _lat;
        var useLng = lng ?? _lng;
        if (useLat == null || useLng == null) {
          await refreshLocation();
          useLat = _lat;
          useLng = _lng;
        }
        if (useLat == null || useLng == null || !_gpsOn) {
          lastLocationError = AttendanceLocationResult.unavailable;
          throw const AttendanceException(AttendanceErrorCode.locationRequired);
        }
        await _punchRemote(
          workplaceId: workplaceId,
          type: type,
          lat: useLat,
          lng: useLng,
        );
      } else {
        _store.patch((s) {
          final workplace = s.workplaceById(workplaceId);
          final at = DateTime.now();
          _punchSeq++;
          final record = AttendancePunchRecord(
            id: 'ph_${at.millisecondsSinceEpoch}_$_punchSeq',
            workplaceId: workplaceId,
            workerId: resolvedWorkerId,
            type: type,
            at: at,
          );

          final memberships = s.memberships.map((m) {
            if (m.workplaceId != workplaceId) return m;

            bool? shiftOpen;
            if (type.isClockIn) {
              shiftOpen = workplace?.clockOutEnabled == true;
            } else if (type.isClockOut) {
              shiftOpen = false;
            }

            return m.copyWith(
              shiftOpen: shiftOpen ?? m.shiftOpen,
              lastPunchLabel: type.labelRu,
              lastPunchAt: at,
            );
          }).toList(growable: false);

          return s.copyWith(
            memberships: memberships,
            punchHistory: [...s.punchHistory, record],
            clearSnooze: true,
          );
        });
      }
      return true;
    } on AttendanceException catch (e) {
      lastPunchError = e;
      return false;
    } catch (e) {
      lastPunchError = AttendanceException.from(e);
      return false;
    }
  }

  Future<void> _punchRemote({
    required String workplaceId,
    required AttendancePunchType type,
    required double lat,
    required double lng,
  }) async {
    final snap = _store.snapshot.value;
    final workplace = snap?.workplaceById(workplaceId);

    final kind = type.isClockIn
        ? 'clock_in'
        : type.isClockOut
            ? 'clock_out'
            : 'custom';
    String? punchTypeId;
    if (kind == 'custom') {
      for (final c in workplace?.customPunches ?? const <AttendanceCustomPunchConfig>[]) {
        if (c.id == type.key || c.label == type.labelRu) {
          punchTypeId = c.id;
          break;
        }
      }
      if (punchTypeId == null && type.key.length == 36) punchTypeId = type.key;
    }

    final clientId = 'local_${DateTime.now().microsecondsSinceEpoch}_$_punchSeq';
    _punchSeq++;
    final punchedAt = DateTime.now();

    try {
      await _remote.submitPunch(
        workplaceId: workplaceId,
        punchKind: kind,
        lat: lat,
        lng: lng,
        punchTypeId: punchTypeId,
        clientPunchId: clientId,
        punchedAt: punchedAt,
      );
      await _store.refreshRemote();
    } on AttendanceException catch (e) {
      if (!e.isRetriableNetwork) rethrow;
      final resolvedWorkerId = _store.selfWorkerId();
      _store.patch((s) {
        final record = AttendancePunchRecord(
          id: clientId,
          workplaceId: workplaceId,
          workerId: resolvedWorkerId,
          type: type,
          at: punchedAt,
        );
        final memberships = s.memberships.map((m) {
          if (m.workplaceId != workplaceId) return m;
          bool? shiftOpen;
          if (type.isClockIn) {
            shiftOpen = workplace?.clockOutEnabled == true;
          } else if (type.isClockOut) {
            shiftOpen = false;
          }
          return m.copyWith(
            shiftOpen: shiftOpen ?? m.shiftOpen,
            lastPunchLabel: type.labelRu,
            lastPunchAt: punchedAt,
          );
        }).toList(growable: false);
        return s.copyWith(
          memberships: memberships,
          punchHistory: [...s.punchHistory, record],
          clearSnooze: true,
        );
      });
      await _outbox.enqueue(
        AttendanceOutboxItem(
          id: 'punch_$clientId',
          kind: AttendanceOutboxKind.punch,
          payload: {
            'workplace_id': workplaceId,
            'punch_kind': kind,
            'lat': lat,
            'lng': lng,
            'punch_type_id': punchTypeId,
            'client_punch_id': clientId,
            'punched_at': punchedAt.toUtc().toIso8601String(),
          },
          createdAt: DateTime.now().toUtc(),
        ),
      );
    }
  }

  Future<bool> requestPunchCorrection({required String punchId, String? note}) async {
    lastPunchError = null;
    try {
      await _remote.requestPunchCorrection(punchId: punchId, note: note);
      return true;
    } on AttendanceException catch (e) {
      lastPunchError = e;
      return false;
    } catch (e) {
      lastPunchError = AttendanceException.from(e);
      return false;
    }
  }

  Future<void> cancelLastPunch({String? comment}) async {
    final workplaceId = _workplaceId;
    if (workplaceId == null) return;
    final resolvedWorkerId = _store.selfWorkerId();

    void optimistic() {
      _store.patch((s) {
        final last = s.lastPunchFor(workplaceId: workplaceId, workerId: resolvedWorkerId);
        if (last == null) return s;

        final history = s.punchHistory.map((e) {
          if (e.id != last.id) return e;
          return e.copyWith(
            cancelled: true,
            cancelComment: comment?.trim().isEmpty == true ? null : comment?.trim(),
          );
        }).toList(growable: false);

        final memberships = s.memberships.map((m) {
          if (m.workplaceId != workplaceId) return m;
          if (last.type.isClockIn) return m.copyWith(shiftOpen: false);
          if (last.type.isClockOut) return m.copyWith(shiftOpen: true);
          return m;
        }).toList(growable: false);

        return s.copyWith(punchHistory: history, memberships: memberships);
      });
    }

    if (!_store.isRemote) {
      optimistic();
      return;
    }

    final last = _store.snapshot.value?.lastPunchFor(
      workplaceId: workplaceId,
      workerId: resolvedWorkerId,
    );
    if (last == null) return;

    try {
      await _remote.cancelPunch(punchId: last.id, note: comment);
      await _store.refreshRemote();
    } on AttendanceException catch (e) {
      if (!e.isRetriableNetwork) rethrow;
      optimistic();
      await _outbox.enqueue(
        AttendanceOutboxItem(
          id: 'punch_cancel_${last.id}',
          kind: AttendanceOutboxKind.punchCancel,
          payload: {
            'punch_id': last.id,
            if (comment != null && comment.trim().isNotEmpty) 'note': comment.trim(),
          },
          createdAt: DateTime.now().toUtc(),
        ),
      );
    }
  }

  void snoozePending({Duration duration = const Duration(minutes: 30)}) {
    _store.patch((s) => s.copyWith(snoozePendingUntil: DateTime.now().add(duration)));
  }

  void toggleMockGeofence() {
    _store.patch((s) => s.copyWith(mockInGeofence: !s.mockInGeofence));
  }

  void toggleMockGps() {
    _store.patch((s) => s.copyWith(mockGpsEnabled: !s.mockGpsEnabled));
  }
}

sealed class AttendancePunchState {
  const AttendancePunchState();

  const factory AttendancePunchState.initial() = AttendancePunchInitial;
  const factory AttendancePunchState.missing() = AttendancePunchMissing;
  const factory AttendancePunchState.ready({
    required String workplaceId,
    required AttendanceSnapshot snapshot,
    required AttendanceWorkplace workplace,
    required AttendanceMembership membership,
    required String workerId,
    required bool isRemote,
    required List<AttendancePunchRecord> history,
    required bool gpsOn,
    required bool inZone,
    required bool locating,
  }) = AttendancePunchReady;
}

final class AttendancePunchInitial extends AttendancePunchState {
  const AttendancePunchInitial();
}

final class AttendancePunchMissing extends AttendancePunchState {
  const AttendancePunchMissing();
}

final class AttendancePunchReady extends AttendancePunchState {
  const AttendancePunchReady({
    required this.workplaceId,
    required this.snapshot,
    required this.workplace,
    required this.membership,
    required this.workerId,
    required this.isRemote,
    required this.history,
    required this.gpsOn,
    required this.inZone,
    required this.locating,
  });

  final String workplaceId;
  final AttendanceSnapshot snapshot;
  final AttendanceWorkplace workplace;
  final AttendanceMembership membership;
  final String workerId;
  final bool isRemote;
  final List<AttendancePunchRecord> history;
  final bool gpsOn;
  final bool inZone;
  final bool locating;
}
