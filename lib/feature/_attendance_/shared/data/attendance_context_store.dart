import 'package:clover/core/storage/domain/repositories/i_app_storage.dart';
import 'package:clover/feature/_attendance_/shared/data/attendance_error.dart';
import 'package:clover/feature/_attendance_/shared/data/attendance_remote_repository.dart';
import 'package:clover/feature/_attendance_/shared/data/attendance_workers_mock.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_absence.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_custom_punch_config.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_day_time.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_duty_roster.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_membership.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_overtime_entry.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_payroll_models.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_punch_record.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_punch_type.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_snapshot.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_workplace.dart';
import 'package:clover/feature/_chat_/chat/data/repository/chat_repository.dart';
import 'package:injectable/injectable.dart';
import 'package:flutter/foundation.dart';

/// DM после invite — открыть вкладку Chat / ChatRoute.
class AttendanceInviteDm {
  const AttendanceInviteDm({
    required this.conversationId,
    required this.otherUserId,
    required this.username,
  });

  final String conversationId;
  final String otherUserId;
  final String username;
}

@lazySingleton
class AttendanceContextStore {
  AttendanceContextStore(this._storage, this._remote, this._chat);

  final IAppStorage _storage;
  final AttendanceRemoteRepository _remote;
  final ChatRepository _chat;
  final ValueNotifier<AttendanceSnapshot?> snapshot = ValueNotifier(null);

  static String _mockKey(String userId) => 'resource_attendance_mock_enabled_$userId';
  static String _remoteKey(String userId) => 'resource_attendance_remote_enabled_$userId';

  bool _loadedForUser = false;
  bool _useRemote = false;
  int _punchSeq = 0;
  String? _boundUserId;

  bool get isRemote => _useRemote;

  /// Hydrate for the signed-in user without pages touching Supabase.
  Future<void> hydrateCurrent() async {
    final uid = _remote.currentUserId;
    if (uid == null || uid.isEmpty) {
      snapshot.value = null;
      _loadedForUser = true;
      return;
    }
    await hydrate(uid);
  }

  Future<void> hydrate(String userId) async {
    if (_loadedForUser && snapshot.value != null && _boundUserId == userId && _useRemote) return;
    _boundUserId = userId;

    // Remote-first: без mock-демо по умолчанию.
    _useRemote = true;
    await _storage.write<bool>(key: _remoteKey(userId), value: true);
    await _storage.write<bool>(key: _mockKey(userId), value: false);

    try {
      snapshot.value = await _remote.bootstrap();
    } catch (_) {
      snapshot.value = AttendanceSnapshot(fromRemote: true);
    }
    _loadedForUser = true;
  }

  Future<void> enableMockDemo([String? userId]) async {
    final uid = userId ?? _remote.currentUserId;
    if (uid == null || uid.isEmpty) return;
    await _storage.write<bool>(key: _remoteKey(uid), value: false);
    await _storage.write<bool>(key: _mockKey(uid), value: true);
    _useRemote = false;
    _boundUserId = uid;
    snapshot.value = _mockSnapshot();
    _loadedForUser = true;
  }

  /// Включить live backend (bootstrap). Mock выключается.
  Future<void> enableRemote([String? userId]) async {
    final uid = userId ?? _remote.currentUserId;
    if (uid == null || uid.isEmpty) return;
    await _storage.write<bool>(key: _mockKey(uid), value: false);
    await _storage.write<bool>(key: _remoteKey(uid), value: true);
    _useRemote = true;
    _boundUserId = uid;
    snapshot.value = await _remote.bootstrap();
    _loadedForUser = true;
  }

  Future<void> refreshRemote() async {
    if (!_useRemote) return;
    snapshot.value = await _remote.bootstrap();
  }

  Future<void> disableMock(String userId) async {
    await _storage.write<bool>(key: _mockKey(userId), value: false);
    await _storage.write<bool>(key: _remoteKey(userId), value: false);
    _useRemote = false;
    snapshot.value = null;
    _loadedForUser = true;
  }

  void patch(AttendanceSnapshot Function(AttendanceSnapshot current) fn) {
    final current = snapshot.value;
    if (current == null) return;
    snapshot.value = fn(current);
  }

  AttendanceSnapshot _mockSnapshot() {
    final now = DateTime.now();
    const cafe = AttendanceWorkplace(
      id: 'wp_cafe_abay',
      name: 'Кафе на Абая',
      latitude: 43.24210,
      longitude: 76.95620,
      geofenceRadiusM: 150,
      isAdmin: true,
      clockInEnabled: true,
      clockOutEnabled: true,
      clockInScheduledTime: AttendanceDayTime(hour: 9, minute: 0),
      customPunches: [
        AttendanceCustomPunchConfig(
          label: 'Обед',
          scheduledTime: AttendanceDayTime(hour: 13, minute: 0),
        ),
      ],
      payrollRules: AttendancePayrollRules(
        lateDeductsPay: true,
        overtimeAddsPay: true,
        absenceDeductsPay: true,
        partialDayDeductsPay: true,
      ),
      workerBaseSalaries: {
        'worker_you': 350000,
        'worker_ivan': 280000,
        'worker_aidana': 220000,
      },
      dutyRoster: AttendanceDutyRoster(
        workerIds: ['worker_you', 'worker_ivan', 'worker_aidana'],
        workingWeekdays: {1, 2, 3, 4, 5, 6},
      ),
    );
    const salon = AttendanceWorkplace(
      id: 'wp_salon',
      name: 'Салон Beauty',
      latitude: 43.25680,
      longitude: 76.92840,
      isAdmin: true,
      clockInEnabled: true,
      clockOutEnabled: false,
    );

    return AttendanceSnapshot(
      workplaces: const [cafe, salon],
      memberships: const [
        AttendanceMembership(
          workplaceId: 'wp_cafe_abay',
          workplaceName: 'Кафе на Абая',
          shiftOpen: false,
          ackVersion: 1,
          configVersion: 1,
        ),
      ],
      punchHistory: [
        AttendancePunchRecord(
          id: 'ph_1',
          workplaceId: 'wp_cafe_abay',
          workerId: 'worker_you',
          type: AttendancePunchType.clockIn,
          at: DateTime(now.year, now.month, now.day - 1, 9, 4),
        ),
        AttendancePunchRecord(
          id: 'ph_2',
          workplaceId: 'wp_cafe_abay',
          workerId: 'worker_you',
          type: AttendancePunchType.clockOut,
          at: DateTime(now.year, now.month, now.day - 1, 18, 12),
        ),
        AttendancePunchRecord(
          id: 'ph_3',
          workplaceId: 'wp_cafe_abay',
          workerId: 'worker_you',
          type: AttendancePunchType.clockIn,
          at: DateTime(now.year, now.month, now.day, 9, 1),
        ),
      ],
      absences: [
        AttendanceAbsenceEntry(
          id: 'abs_1',
          workplaceId: 'wp_cafe_abay',
          workerId: 'worker_ivan',
          kind: AttendanceAbsenceKind.vacation,
          startDate: DateTime(now.year, now.month, 10),
          endDate: DateTime(now.year, now.month, 12),
          note: 'Отпуск (mock)',
        ),
      ],
      overtimeEntries: [
        AttendanceOvertimeEntry(
          id: 'ot_1',
          workplaceId: 'wp_cafe_abay',
          workerId: 'worker_you',
          workerName: 'Вы',
          date: DateTime(now.year, now.month, now.day - 2),
          hours: 8,
          status: AttendanceOvertimeStatus.approved,
        ),
        AttendanceOvertimeEntry(
          id: 'ot_2',
          workplaceId: 'wp_cafe_abay',
          workerId: 'worker_ivan',
          workerName: 'Иван',
          date: DateTime(now.year, now.month, now.day - 1),
          hours: 3,
          status: AttendanceOvertimeStatus.pending,
        ),
      ],
      mockInGeofence: true,
      mockGpsEnabled: true,
      mockUnreadAttendanceChat: true,
    );
  }

  void snoozePending({Duration duration = const Duration(minutes: 30)}) {
    patch((s) => s.copyWith(snoozePendingUntil: DateTime.now().add(duration)));
  }

  void clearSnooze() => patch((s) => s.copyWith(clearSnooze: true));

  void toggleMockGeofence() => patch((s) => s.copyWith(mockInGeofence: !s.mockInGeofence));

  void toggleMockGps() => patch((s) => s.copyWith(mockGpsEnabled: !s.mockGpsEnabled));

  String selfWorkerId() {
    if (_useRemote) {
      final uid = snapshot.value?.memberships
          .map((m) => m.profileId)
          .whereType<String>()
          .firstOrNull;
      return uid ?? 'worker_you';
    }
    return 'worker_you';
  }

  void punch({
    required String workplaceId,
    required AttendancePunchType type,
    String? workerId,
    double? lat,
    double? lng,
  }) {
    final resolvedWorkerId = workerId ?? selfWorkerId();
    if (_useRemote) {
      _punchRemote(workplaceId: workplaceId, type: type, lat: lat, lng: lng);
      return;
    }
    patch((s) {
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

  Future<void> _punchRemote({
    required String workplaceId,
    required AttendancePunchType type,
    double? lat,
    double? lng,
  }) async {
    final snap = snapshot.value;
    final workplace = snap?.workplaceById(workplaceId);
    final useLat = lat ?? workplace?.latitude;
    final useLng = lng ?? workplace?.longitude;
    if (useLat == null || useLng == null) {
      throw const AttendanceException(AttendanceErrorCode.locationRequired);
    }

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

    await _remote.submitPunch(
      workplaceId: workplaceId,
      punchKind: kind,
      lat: useLat,
      lng: useLng,
      punchTypeId: punchTypeId,
      clientPunchId: clientId,
    );
    await refreshRemote();
  }

  void cancelLastPunch({
    required String workplaceId,
    String? workerId,
    String? comment,
  }) {
    final resolvedWorkerId = workerId ?? selfWorkerId();
    if (_useRemote) {
      final last = snapshot.value?.lastPunchFor(workplaceId: workplaceId, workerId: resolvedWorkerId);
      if (last == null) return;
      _remote.cancelPunch(punchId: last.id, note: comment).then((_) => refreshRemote());
      return;
    }
    patch((s) {
      final last = s.lastPunchFor(workplaceId: workplaceId, workerId: resolvedWorkerId);
      if (last == null) return s;

      final history = s.punchHistory.map((e) {
        if (e.id != last.id) return e;
        return e.copyWith(cancelled: true, cancelComment: comment?.trim().isEmpty == true ? null : comment?.trim());
      }).toList(growable: false);

      return s.copyWith(punchHistory: history);
    });
  }

  void updateGeofence({
    required String workplaceId,
    required double latitude,
    required double longitude,
    required int geofenceRadiusM,
  }) {
    if (_useRemote) {
      _remote
          .updateWorkplaceSettings(
            workplaceId: workplaceId,
            lat: latitude,
            lng: longitude,
            geofenceRadiusM: geofenceRadiusM,
          )
          .then((_) => refreshRemote());
      return;
    }
    patch((s) {
      final workplaces = s.workplaces.map((w) {
        if (w.id != workplaceId) return w;
        return w.copyWith(latitude: latitude, longitude: longitude, geofenceRadiusM: geofenceRadiusM);
      }).toList(growable: false);
      return s.copyWith(workplaces: workplaces);
    });
  }

  void updatePunchConfig({
    required String workplaceId,
    required bool clockInEnabled,
    required bool clockOutEnabled,
    AttendanceDayTime? clockInScheduledTime,
    AttendanceDayTime? clockOutScheduledTime,
    bool clearClockInScheduledTime = false,
    bool clearClockOutScheduledTime = false,
    required List<AttendanceCustomPunchConfig> customPunches,
  }) {
    if (_useRemote) {
      String? fmt(AttendanceDayTime? t) =>
          t == null ? null : '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';
      _remote
          .updateWorkplaceSettings(
            workplaceId: workplaceId,
            clockInEnabled: clockInEnabled,
            clockOutEnabled: clockOutEnabled,
            clockInScheduled: clearClockInScheduledTime ? null : fmt(clockInScheduledTime),
            clockOutScheduled: clearClockOutScheduledTime ? null : fmt(clockOutScheduledTime),
          )
          .then((_) => _remote.replaceCustomPunchTypes(workplaceId: workplaceId, customPunches: customPunches))
          .then((_) => refreshRemote());
      return;
    }
    patch((s) {
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

  void updatePayrollRules({required String workplaceId, required AttendancePayrollRules rules}) {
    patch((s) {
      final workplaces = s.workplaces.map((w) {
        if (w.id != workplaceId) return w;
        return w.copyWith(payrollRules: rules);
      }).toList(growable: false);
      return s.copyWith(workplaces: workplaces);
    });
  }

  void updateWorkerBaseSalary({
    required String workplaceId,
    required String workerId,
    required int baseSalary,
  }) {
    patch((s) {
      final workplaces = s.workplaces.map((w) {
        if (w.id != workplaceId) return w;
        final salaries = Map<String, int>.from(w.workerBaseSalaries);
        salaries[workerId] = baseSalary;
        return w.copyWith(workerBaseSalaries: salaries);
      }).toList(growable: false);
      return s.copyWith(workplaces: workplaces);
    });
  }

  void updateDutyRoster({required String workplaceId, required AttendanceDutyRoster roster}) {
    patch((s) {
      final workplaces = s.workplaces.map((w) {
        if (w.id != workplaceId) return w;
        return w.copyWith(dutyRoster: roster);
      }).toList(growable: false);
      return s.copyWith(workplaces: workplaces);
    });
  }

  void addAbsence(AttendanceAbsenceEntry entry) {
    if (_useRemote) {
      _remote
          .upsertAbsence(
            workplaceId: entry.workplaceId,
            profileId: entry.workerId,
            kind: entry.kind,
            startDate: entry.startDate,
            endDate: entry.endDate,
            note: entry.note,
            absenceId: entry.id.startsWith('abs_') ? null : entry.id,
          )
          .then((_) => refreshRemote());
      return;
    }
    patch((s) => s.copyWith(absences: [...s.absences, entry]));
  }

  void setWorkerStatus({
    required String workplaceId,
    required String workerId,
    required AttendanceWorkerInviteStatus status,
  }) {
    if (_useRemote) {
      final m = snapshot.value?.membershipForProfile(workplaceId: workplaceId, profileId: workerId);
      final mid = m?.id;
      if (mid == null) return;
      final Future<void> op = switch (status) {
        AttendanceWorkerInviteStatus.accepted => _remote.acceptInvite(mid),
        AttendanceWorkerInviteStatus.declined => _remote.rejectInvite(mid),
        AttendanceWorkerInviteStatus.archived => _remote.archiveMember(mid),
        AttendanceWorkerInviteStatus.pending => _remote.reinviteMember(mid),
      };
      op.then((_) => refreshRemote());
      return;
    }
    patch((s) {
      final overrides = Map<String, Map<String, AttendanceWorkerInviteStatus>>.from(
        s.workerStatusOverrides.map((k, v) => MapEntry(k, Map<String, AttendanceWorkerInviteStatus>.from(v))),
      );
      final workplaceMap = Map<String, AttendanceWorkerInviteStatus>.from(overrides[workplaceId] ?? {});
      workplaceMap[workerId] = status;
      overrides[workplaceId] = workplaceMap;
      return s.copyWith(workerStatusOverrides: overrides);
    });
  }

  /// Invite через DM во вкладке Chat: pending, пока человек не Accept.
  /// Возвращает DM для навигации; в mock — null (открывать mock-чат компании).
  Future<AttendanceInviteDm?> sendChatInvite({
    required String workplaceId,
    required AttendanceWorkerListItem candidate,
  }) async {
    if (!_useRemote) {
      patch((s) {
        var extras = s.extraWorkers;
        final inBase = AttendanceWorkersMock.forWorkplace(workplaceId).any((w) => w.id == candidate.id);
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

    final snap = snapshot.value;
    final workplaceName = snap?.workplaceById(workplaceId)?.name ?? 'компанию';
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
    await _chat.sendTextMessage(
      conversationId: conversationId,
      text: 'Стать частью команды · $workplaceName',
    );
    await refreshRemote();

    final username = candidate.username.trim().isEmpty ? candidate.displayName : candidate.username;
    return AttendanceInviteDm(
      conversationId: conversationId,
      otherUserId: candidate.id,
      username: username,
    );
  }

  /// Accept invite → активный + (mock) участник группового чата компании.
  void acceptInvite({
    required String workplaceId,
    required String workerId,
  }) {
    if (_useRemote) {
      final m = snapshot.value?.membershipForProfile(workplaceId: workplaceId, profileId: workerId);
      final mid = m?.id;
      if (mid == null) return;
      _remote.acceptInvite(mid).then((_) => refreshRemote());
      return;
    }
    setWorkerStatus(
      workplaceId: workplaceId,
      workerId: workerId,
      status: AttendanceWorkerInviteStatus.accepted,
    );
    clearUnreadChat();
  }

  /// Reject invite → вне команды, убирается из «Ожидают».
  void rejectInvite({
    required String workplaceId,
    required String workerId,
  }) {
    if (_useRemote) {
      final m = snapshot.value?.membershipForProfile(workplaceId: workplaceId, profileId: workerId);
      final mid = m?.id;
      if (mid == null) return;
      _remote.rejectInvite(mid).then((_) => refreshRemote());
      return;
    }
    setWorkerStatus(
      workplaceId: workplaceId,
      workerId: workerId,
      status: AttendanceWorkerInviteStatus.declined,
    );
    clearUnreadChat();
  }

  void setOvertimeStatus({
    required String entryId,
    required AttendanceOvertimeStatus status,
  }) {
    patch((s) {
      final entries = s.overtimeEntries.map((e) {
        if (e.id != entryId) return e;
        return e.copyWith(status: status);
      }).toList(growable: false);
      return s.copyWith(overtimeEntries: entries);
    });
  }

  void addOvertimeRequest(AttendanceOvertimeEntry entry) {
    patch((s) => s.copyWith(overtimeEntries: [...s.overtimeEntries, entry]));
  }

  void ackConfig(String workplaceId) {
    if (_useRemote) {
      _remote.ackConfig(workplaceId).then((_) => refreshRemote());
      return;
    }
    patch((s) {
      final memberships = s.memberships.map((m) {
        if (m.workplaceId != workplaceId) return m;
        return m.copyWith(ackVersion: m.configVersion);
      }).toList(growable: false);
      return s.copyWith(memberships: memberships);
    });
  }

  Future<void> createWorkplace({
    required String name,
    double? lat,
    double? lng,
    int geofenceRadiusM = 150,
  }) async {
    if (!_useRemote) return;
    await _remote.createWorkplace(
      name: name,
      lat: lat,
      lng: lng,
      geofenceRadiusM: geofenceRadiusM,
    );
    await refreshRemote();
  }

  void simulateConfigUpdate(String workplaceId) {
    patch((s) {
      final memberships = s.memberships.map((m) {
        if (m.workplaceId != workplaceId) return m;
        return m.copyWith(configVersion: m.configVersion + 1);
      }).toList(growable: false);
      return s.copyWith(memberships: memberships, mockUnreadAttendanceChat: true);
    });
  }

  void clearUnreadChat() => patch((s) => s.copyWith(mockUnreadAttendanceChat: false));
}
