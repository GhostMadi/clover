import 'package:clover/core/storage/domain/repositories/i_app_storage.dart';
import 'package:clover/feature/_attendance_/shared/data/attendance_outbox.dart';
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
import 'package:injectable/injectable.dart';
import 'package:flutter/widgets.dart';

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

/// Session bootstrap only. Mutations live in feature cubits
/// (hub / workers / punch / settings / absences / OT / company chat).
@lazySingleton
class AttendanceContextStore with WidgetsBindingObserver {
  AttendanceContextStore(this._storage, this._remote, this._outbox) {
    WidgetsBinding.instance.addObserver(this);
  }

  final IAppStorage _storage;
  final AttendanceRemoteRepository _remote;
  final AttendanceOutbox _outbox;
  final ValueNotifier<AttendanceSnapshot?> snapshot = ValueNotifier(null);

  static String _mockKey(String userId) => 'resource_attendance_mock_enabled_$userId';
  static String _remoteKey(String userId) => 'resource_attendance_remote_enabled_$userId';

  bool _loadedForUser = false;
  bool _useRemote = false;
  String? _boundUserId;

  /// After empty bootstrap: skip Home network until user opens attendance.
  bool _knownNonParticipant = false;

  bool get isRemote => _useRemote;

  bool get isKnownNonParticipant => _knownNonParticipant;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _useRemote && !_knownNonParticipant) {
      // ignore: discarded_futures
      flushOutboxAndRefresh();
    }
  }

  /// Hydrate for the signed-in user without pages touching Supabase.
  Future<void> hydrateCurrent({bool force = false}) async {
    final uid = _remote.currentUserId;
    if (uid == null || uid.isEmpty) {
      snapshot.value = null;
      _loadedForUser = true;
      _knownNonParticipant = true;
      return;
    }
    await hydrate(uid, force: force);
  }

  Future<void> hydrate(String userId, {bool force = false}) async {
    if (!force &&
        _knownNonParticipant &&
        _boundUserId == userId &&
        _loadedForUser &&
        (snapshot.value == null || !_snapshotHasAttendance(snapshot.value!))) {
      return;
    }

    if (_loadedForUser && snapshot.value != null && _boundUserId == userId && _useRemote && !force) {
      if (_knownNonParticipant) return;
      await flushOutboxAndRefresh();
      return;
    }
    _boundUserId = userId;

    // Remote-first: без mock-демо по умолчанию.
    _useRemote = true;
    await _storage.write<bool>(key: _remoteKey(userId), value: true);
    await _storage.write<bool>(key: _mockKey(userId), value: false);

    try {
      final boot = await _remote.bootstrap();
      snapshot.value = boot;
      _knownNonParticipant = !_snapshotHasAttendance(boot);
      await _outbox.refreshCount(userId);
      if (!_knownNonParticipant) {
        await flushOutboxAndRefresh();
      }
    } catch (_) {
      snapshot.value = AttendanceSnapshot(fromRemote: true);
      _knownNonParticipant = true;
      await _outbox.refreshCount(userId);
    }
    _loadedForUser = true;
  }

  static bool _snapshotHasAttendance(AttendanceSnapshot s) {
    return s.workplaces.isNotEmpty || s.memberships.isNotEmpty || s.rosterMemberships.isNotEmpty;
  }

  /// Wipe memory + outbox prefs for logout / account switch.
  Future<void> clearForSignOut() async {
    final uid = _boundUserId ?? _remote.currentUserId;
    snapshot.value = null;
    _loadedForUser = false;
    _useRemote = false;
    _knownNonParticipant = false;
    _boundUserId = null;
    if (uid != null && uid.isNotEmpty) {
      await _outbox.clearForUser(uid);
      await _storage.delete(key: _mockKey(uid));
      await _storage.delete(key: _remoteKey(uid));
    }
  }

  Future<void> enableMockDemo([String? userId]) async {
    final uid = userId ?? _remote.currentUserId;
    if (uid == null || uid.isEmpty) return;
    await _storage.write<bool>(key: _remoteKey(uid), value: false);
    await _storage.write<bool>(key: _mockKey(uid), value: true);
    _useRemote = false;
    _boundUserId = uid;
    _knownNonParticipant = false;
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
    _knownNonParticipant = false;
    snapshot.value = await _remote.bootstrap();
    await flushOutboxAndRefresh();
    _loadedForUser = true;
  }

  Future<void> refreshRemote() async {
    if (!_useRemote) return;
    final boot = await _remote.bootstrap();
    snapshot.value = boot;
    _knownNonParticipant = !_snapshotHasAttendance(boot);
  }

  /// Flush outbox then re-bootstrap when anything was sent (server wins).
  Future<void> flushOutboxAndRefresh() async {
    if (!_useRemote) return;
    final flushed = await _outbox.flush();
    if (flushed > 0) {
      snapshot.value = await _remote.bootstrap();
    }
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

  void clearUnreadChat() => patch((s) => s.copyWith(mockUnreadAttendanceChat: false));

  String selfWorkerId() {
    if (_useRemote) {
      final uid = snapshot.value?.memberships.map((m) => m.profileId).whereType<String>().firstOrNull;
      return uid ?? 'worker_you';
    }
    return 'worker_you';
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
      extraWorkers: AttendanceWorkersMock.teamSeed,
      mockInGeofence: true,
      mockGpsEnabled: true,
      mockUnreadAttendanceChat: true,
    );
  }
}
