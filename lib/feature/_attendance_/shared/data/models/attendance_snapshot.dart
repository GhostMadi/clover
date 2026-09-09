import 'package:clover/feature/_attendance_/shared/data/models/attendance_absence.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_membership.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_overtime_entry.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_pending_punch.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_punch_record.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_worker.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_workplace.dart';

class AttendanceSnapshot {
  const AttendanceSnapshot({
    this.workplaces = const [],
    this.folders = const [],
    this.memberships = const [],
    this.rosterMemberships = const [],
    this.punchHistory = const [],
    this.absences = const [],
    this.overtimeEntries = const [],
    this.workerStatusOverrides = const {},
    this.extraWorkers = const [],
    this.mockInGeofence = true,
    this.mockGpsEnabled = true,
    this.mockUnreadAttendanceChat = false,
    this.fromRemote = false,
    this.profileDisplayNames = const {},
    this.profileUsernames = const {},
    this.snoozePendingUntil,
  });

  final List<AttendanceWorkplace> workplaces;
  final List<AttendanceFolder> folders;

  /// Memberships of the current user (worker hub / punch / ack).
  final List<AttendanceMembership> memberships;

  /// All memberships visible to admin (roster); empty in mock mode.
  final List<AttendanceMembership> rosterMemberships;
  final List<AttendancePunchRecord> punchHistory;
  final List<AttendanceAbsenceEntry> absences;
  final List<AttendanceOvertimeEntry> overtimeEntries;

  /// workplaceId → workerId → status (override mock).
  final Map<String, Map<String, AttendanceWorkerInviteStatus>> workerStatusOverrides;

  /// Invite-кандидаты, которых добавили сверх базового mock-списка.
  final List<AttendanceWorkerListItem> extraWorkers;
  final bool mockInGeofence;
  final bool mockGpsEnabled;
  final bool mockUnreadAttendanceChat;
  final DateTime? snoozePendingUntil;

  /// When true, [workersFor] is derived from memberships (live backend), not mock roster.
  final bool fromRemote;

  /// profile_id → display name / @username (из profiles).
  final Map<String, String> profileDisplayNames;
  final Map<String, String> profileUsernames;

  bool get isAdmin => workplaces.any((w) => w.isAdmin);

  bool get isWorker => memberships.any((m) => m.isActive || m.isPending);

  bool get showProfileWorkerButton => isWorker;

  AttendanceWorkplace? workplaceById(String id) {
    for (final w in workplaces) {
      if (w.id == id) return w;
    }
    return null;
  }

  AttendanceMembership? membershipByWorkplace(String workplaceId) {
    AttendanceMembership? pending;
    for (final m in memberships) {
      if (m.workplaceId != workplaceId) continue;
      if (m.isActive) return m;
      if (m.isPending) pending ??= m;
    }
    return pending;
  }

  AttendanceMembership? membershipById(String membershipId) {
    for (final m in memberships) {
      if (m.id == membershipId) return m;
    }
    return null;
  }

  AttendanceMembership? membershipForProfile({
    required String workplaceId,
    required String profileId,
  }) {
    for (final m in rosterMemberships.isEmpty ? memberships : rosterMemberships) {
      if (m.workplaceId == workplaceId && m.profileId == profileId) return m;
    }
    return null;
  }

  AttendanceWorkerInviteStatus workerStatus(String workplaceId, String workerId) {
    return workerStatusOverrides[workplaceId]?[workerId] ?? AttendanceWorkerInviteStatus.accepted;
  }

  /// Работники компании с актуальными статусами.
  /// Declined не показываем во вкладках.
  /// Remote / roster: только memberships. Local demo: [extraWorkers] (+ overrides).
  List<AttendanceWorkerListItem> workersFor(String workplaceId) {
    if (fromRemote || rosterMemberships.isNotEmpty || memberships.isNotEmpty) {
      final source = rosterMemberships.isEmpty ? memberships : rosterMemberships;
      return source
          .where((m) => m.workplaceId == workplaceId && m.profileId != null)
          .where((m) => m.status != AttendanceWorkerInviteStatus.declined)
          .map((m) {
            final id = m.profileId!;
            final title = profileDisplayNames[id];
            final username = profileUsernames[id] ?? '';
            return AttendanceWorkerListItem(
              id: id,
              displayName: (title != null && title.isNotEmpty)
                  ? title
                  : (id.length > 8 ? '${id.substring(0, 8)}…' : id),
              username: username,
              status: m.status,
              hasAttendanceWorkTag: m.hasAttendanceWorkTag,
            );
          })
          .toList(growable: false);
    }
    return extraWorkers
        .where((w) => !w.isDeclined)
        .map((w) => w.copyWith(status: workerStatus(workplaceId, w.id)))
        .toList(growable: false);
  }

  AttendanceAbsenceEntry? absenceCovering({
    required String workplaceId,
    required String workerId,
    required DateTime day,
  }) {
    for (final e in absences) {
      if (e.workplaceId == workplaceId && e.workerId == workerId && e.covers(day)) {
        return e;
      }
    }
    return null;
  }

  List<AttendancePunchRecord> punchHistoryFor({
    required String workplaceId,
    required String workerId,
    bool includeCancelled = false,
  }) {
    final list = punchHistory
        .where(
          (e) =>
              e.workplaceId == workplaceId &&
              e.workerId == workerId &&
              (includeCancelled || !e.cancelled),
        )
        .toList(growable: false);
    list.sort((a, b) => b.at.compareTo(a.at));
    return list;
  }

  AttendancePunchRecord? lastPunchFor({
    required String workplaceId,
    required String workerId,
  }) {
    final list = punchHistoryFor(workplaceId: workplaceId, workerId: workerId);
    return list.isEmpty ? null : list.first;
  }

  bool hasAbsenceOn({
    required String workplaceId,
    required String workerId,
    required DateTime day,
  }) {
    return absences.any(
      (e) => e.workplaceId == workplaceId && e.workerId == workerId && e.covers(day),
    );
  }

  int approvedOvertimeHours({
    required String workplaceId,
    required String workerId,
  }) {
    return overtimeEntries
        .where(
          (e) =>
              e.workplaceId == workplaceId &&
              e.workerId == workerId &&
              e.status == AttendanceOvertimeStatus.approved,
        )
        .fold(0, (sum, e) => sum + e.hours);
  }

  AttendancePendingPunch? resolvePendingPunch({DateTime? now}) {
    final clock = now ?? DateTime.now();
    if (snoozePendingUntil != null && clock.isBefore(snoozePendingUntil!)) {
      return null;
    }

    for (final m in memberships) {
      if (!m.isActive || m.needsAck || !m.hasAttendanceWorkTag) continue;

      final workplace = workplaceById(m.workplaceId);
      if (workplace == null) continue;

      if (!m.shiftOpen && workplace.clockInEnabled) {
        // Geofence проверяется на экране punch / GPS — pending только напоминает.
        return AttendancePendingPunch(
          workplaceId: m.workplaceId,
          workplaceName: m.workplaceName,
          kind: AttendancePendingKind.clockIn,
        );
      }
      if (m.shiftOpen && workplace.clockOutEnabled) {
        return AttendancePendingPunch(
          workplaceId: m.workplaceId,
          workplaceName: m.workplaceName,
          kind: AttendancePendingKind.clockOut,
        );
      }
    }
    return null;
  }

  AttendanceSnapshot copyWith({
    List<AttendanceWorkplace>? workplaces,
    List<AttendanceFolder>? folders,
    List<AttendanceMembership>? memberships,
    List<AttendanceMembership>? rosterMemberships,
    List<AttendancePunchRecord>? punchHistory,
    List<AttendanceAbsenceEntry>? absences,
    List<AttendanceOvertimeEntry>? overtimeEntries,
    Map<String, Map<String, AttendanceWorkerInviteStatus>>? workerStatusOverrides,
    List<AttendanceWorkerListItem>? extraWorkers,
    bool? mockInGeofence,
    bool? mockGpsEnabled,
    bool? mockUnreadAttendanceChat,
    bool? fromRemote,
    Map<String, String>? profileDisplayNames,
    Map<String, String>? profileUsernames,
    DateTime? snoozePendingUntil,
    bool clearSnooze = false,
  }) {
    return AttendanceSnapshot(
      workplaces: workplaces ?? this.workplaces,
      folders: folders ?? this.folders,
      memberships: memberships ?? this.memberships,
      rosterMemberships: rosterMemberships ?? this.rosterMemberships,
      punchHistory: punchHistory ?? this.punchHistory,
      absences: absences ?? this.absences,
      overtimeEntries: overtimeEntries ?? this.overtimeEntries,
      workerStatusOverrides: workerStatusOverrides ?? this.workerStatusOverrides,
      extraWorkers: extraWorkers ?? this.extraWorkers,
      mockInGeofence: mockInGeofence ?? this.mockInGeofence,
      mockGpsEnabled: mockGpsEnabled ?? this.mockGpsEnabled,
      mockUnreadAttendanceChat: mockUnreadAttendanceChat ?? this.mockUnreadAttendanceChat,
      fromRemote: fromRemote ?? this.fromRemote,
      profileDisplayNames: profileDisplayNames ?? this.profileDisplayNames,
      profileUsernames: profileUsernames ?? this.profileUsernames,
      snoozePendingUntil: clearSnooze ? null : (snoozePendingUntil ?? this.snoozePendingUntil),
    );
  }
}
