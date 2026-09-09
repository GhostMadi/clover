import 'package:clover/feature/_attendance_/shared/data/models/attendance_worker.dart';
import 'dart:convert';

import 'package:clover/feature/_attendance_/shared/data/attendance_error.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_absence.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_correction_request.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_custom_punch_config.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_day_time.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_duty_roster.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_membership.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_overtime_entry.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_payroll_models.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_profile_hit.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_punch_record.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_punch_type.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_snapshot.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_workplace.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Concrete Supabase API for attendance (bootstrap / invite / punch / payroll / duty / OT).
@lazySingleton
class AttendanceRemoteRepository {
  AttendanceRemoteRepository(this._client);

  final SupabaseClient _client;

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } catch (e) {
      throw AttendanceException.from(e);
    }
  }

  String? get currentUserId => _client.auth.currentUser?.id.trim();

  /// Поиск людей по нику / имени для invite.
  Future<List<AttendanceProfileHit>> searchProfiles(
    String query, {
    Set<String> excludeProfileIds = const {},
  }) => _guard(() async {
    final uid = currentUserId;
    if (uid == null || uid.isEmpty) return const [];

    final q = query.trim().replaceFirst(RegExp(r'^@+'), '');
    var builder = _client
        .from('profiles')
        .select('id, username, full_name, avatar_url')
        .neq('id', uid);

    if (q.isNotEmpty) {
      final pattern = '%$q%';
      builder = builder.or('username.ilike.$pattern,full_name.ilike.$pattern');
    }

    final res = await builder.order('username').limit(20);
    final hits = <AttendanceProfileHit>[];
    for (final raw in res as List) {
      final row = Map<String, dynamic>.from(raw as Map);
      final id = row['id']?.toString().trim() ?? '';
      if (id.isEmpty || excludeProfileIds.contains(id)) continue;
      hits.add(
        AttendanceProfileHit(
          id: id,
          username: row['username']?.toString() ?? 'noName',
          displayName: row['full_name']?.toString(),
          avatarUrl: row['avatar_url']?.toString(),
        ),
      );
    }
    return hits;
  });

  Future<String> revisionMe() => _guard(() async {
    final res = await _client.rpc('attendance_revision_me');
    return res?.toString() ?? '';
  });

  Future<AttendanceSnapshot> bootstrap({DateTime? since}) => _guard(() async {
    // PostgREST матчит по списку аргументов: пустой `{}` ищет функцию без params.
    final res = await _client.rpc(
      'attendance_bootstrap_me',
      params: {'p_since': since?.toUtc().toIso8601String()},
    );
    final map = Map<String, dynamic>.from(res as Map);
    final uid = _client.auth.currentUser?.id;
    var snap = AttendanceBootstrapMapper.fromJson(map, currentUserId: uid);
    snap = await _enrichWorkerLabels(snap);
    return snap;
  });

  Future<AttendanceSnapshot> _enrichWorkerLabels(
    AttendanceSnapshot snap,
  ) async {
    final ids = <String>{
      for (final m in snap.rosterMemberships)
        if (m.profileId != null && m.profileId!.isNotEmpty) m.profileId!,
      for (final o in snap.overtimeEntries)
        if (o.workerId.isNotEmpty) o.workerId,
    };
    if (ids.isEmpty) return snap;

    final res = await _client
        .from('profiles')
        .select('id, username, full_name')
        .inFilter('id', ids.toList());
    final names = <String, String>{};
    final usernames = <String, String>{};
    for (final raw in res as List) {
      final row = Map<String, dynamic>.from(raw as Map);
      final id = row['id']?.toString() ?? '';
      if (id.isEmpty) continue;
      final username = row['username']?.toString().trim() ?? '';
      final fullName = row['full_name']?.toString().trim() ?? '';
      final handle = username.isEmpty
          ? ''
          : (username.startsWith('@') ? username : '@$username');
      names[id] = fullName.isNotEmpty
          ? fullName
          : (handle.isNotEmpty ? handle : id);
      usernames[id] = handle;
    }
    if (names.isEmpty) return snap;
    final overtime = snap.overtimeEntries
        .map(
          (e) => AttendanceOvertimeEntry(
            id: e.id,
            workplaceId: e.workplaceId,
            workerId: e.workerId,
            workerName: names[e.workerId] ?? e.workerName,
            date: e.date,
            hours: e.hours,
            status: e.status,
          ),
        )
        .toList(growable: false);
    return snap.copyWith(
      profileDisplayNames: names,
      profileUsernames: usernames,
      overtimeEntries: overtime,
    );
  }

  Future<String> createWorkplace({
    required String name,
    String? folderId,
    double? lat,
    double? lng,
    int geofenceRadiusM = 150,
  }) => _guard(() async {
    final res = await _client.rpc(
      'attendance_create_workplace',
      params: {
        'p_name': name,
        'p_folder_id': folderId,
        'p_lat': lat,
        'p_lng': lng,
        'p_geofence_radius_m': geofenceRadiusM,
      },
    );
    return res.toString();
  });

  Future<void> updateWorkplaceSettings({
    required String workplaceId,
    String? name,
    double? lat,
    double? lng,
    int? geofenceRadiusM,
    bool? clockInEnabled,
    bool? clockOutEnabled,
    String? clockInScheduled, // HH:MM:SS
    String? clockOutScheduled,
    bool bumpConfig = true,
  }) => _guard(() async {
    await _client.rpc(
      'attendance_update_workplace_settings',
      params: {
        'p_workplace_id': workplaceId,
        'p_name': name,
        'p_lat': lat,
        'p_lng': lng,
        'p_geofence_radius_m': geofenceRadiusM,
        'p_clock_in_enabled': clockInEnabled,
        'p_clock_out_enabled': clockOutEnabled,
        'p_clock_in_scheduled': clockInScheduled,
        'p_clock_out_scheduled': clockOutScheduled,
        'p_bump_config': bumpConfig,
      },
    );
  });

  Future<String> inviteMember({
    required String workplaceId,
    required String profileId,
  }) => _guard(() async {
    final res = await _client.rpc(
      'attendance_invite_member',
      params: {'p_workplace_id': workplaceId, 'p_profile_id': profileId},
    );
    return res.toString();
  });

  Future<void> acceptInvite(String membershipId) => _guard(() async {
    await _client.rpc(
      'attendance_accept_invite',
      params: {'p_membership_id': membershipId},
    );
  });

  Future<void> rejectInvite(String membershipId) => _guard(() async {
    await _client.rpc(
      'attendance_reject_invite',
      params: {'p_membership_id': membershipId},
    );
  });

  Future<void> archiveMember(String membershipId) => _guard(() async {
    await _client.rpc(
      'attendance_archive_member',
      params: {'p_membership_id': membershipId},
    );
  });

  Future<void> reinviteMember(String membershipId) => _guard(() async {
    await _client.rpc(
      'attendance_reinvite_member',
      params: {'p_membership_id': membershipId},
    );
  });

  Future<void> ackConfig(String workplaceId) => _guard(() async {
    await _client.rpc(
      'attendance_ack_config',
      params: {'p_workplace_id': workplaceId},
    );
  });

  Future<String> submitPunch({
    required String workplaceId,
    required String punchKind, // clock_in | clock_out | custom
    required double lat,
    required double lng,
    String? punchTypeId,
    String? clientPunchId,
    DateTime? punchedAt,
  }) => _guard(() async {
    final res = await _client.rpc(
      'submit_attendance_punch',
      params: {
        'p_workplace_id': workplaceId,
        'p_punch_kind': punchKind,
        'p_lat': lat,
        'p_lng': lng,
        'p_punch_type_id': punchTypeId,
        'p_client_punch_id': clientPunchId,
        if (punchedAt != null)
          'p_punched_at': punchedAt.toUtc().toIso8601String(),
      },
    );
    return res.toString();
  });

  Future<void> cancelPunch({required String punchId, String? note}) =>
      _guard(() async {
        await _client.rpc(
          'cancel_attendance_punch',
          params: {'p_punch_id': punchId, 'p_note': note},
        );
      });

  /// Atomically replaces the owner's custom punch types.
  Future<void> replaceCustomPunchTypes({
    required String workplaceId,
    required List<AttendanceCustomPunchConfig> customPunches,
  }) => _guard(() async {
    await _client.rpc(
      'attendance_replace_punch_types',
      params: {
        'p_workplace_id': workplaceId,
        'p_types': [
          for (var i = 0; i < customPunches.length; i++)
            {
              if (customPunches[i].id != null) 'id': customPunches[i].id,
              'label': customPunches[i].label,
              if (customPunches[i].scheduledTime != null)
                'scheduled_time':
                    '${customPunches[i].scheduledTime!.hour.toString().padLeft(2, '0')}:'
                    '${customPunches[i].scheduledTime!.minute.toString().padLeft(2, '0')}',
              'sort_order': i,
            },
        ],
      },
    );
  });

  Future<String> upsertAbsence({
    required String workplaceId,
    required String profileId,
    required AttendanceAbsenceKind kind,
    required DateTime startDate,
    required DateTime endDate,
    String? note,
    String? absenceId,
  }) => _guard(() async {
    final res = await _client.rpc(
      'attendance_upsert_absence',
      params: {
        'p_workplace_id': workplaceId,
        'p_profile_id': profileId,
        'p_kind': kind.key,
        'p_start_date': _dateOnly(startDate),
        'p_end_date': _dateOnly(endDate),
        'p_note': note,
        'p_absence_id': absenceId,
      },
    );
    return res.toString();
  });

  Future<void> updatePayrollSettings({
    required String workplaceId,
    required Map<String, dynamic> payrollRules,
  }) => _guard(() async {
    await _client.rpc(
      'attendance_update_payroll_settings',
      params: {'p_workplace_id': workplaceId, 'p_payroll_rules': payrollRules},
    );
  });

  Future<AttendancePayrollTeamSummary> payrollPreview({
    required String workplaceId,
    required DateTime start,
    required DateTime end,
    Map<String, dynamic>? rulesJson,
  }) => _guard(() async {
    final res = await _client.rpc(
      'attendance_payroll_preview',
      params: {
        'p_workplace_id': workplaceId,
        'p_start': _dateOnly(start),
        'p_end': _dateOnly(end),
        'p_rules': rulesJson,
      },
    );
    return AttendancePayrollTeamSummary.fromJson(
      Map<String, dynamic>.from(res as Map),
    );
  });

  Future<void> updateDutyRoster({
    required String workplaceId,
    required Map<String, dynamic> dutyRoster,
  }) => _guard(() async {
    await _client.rpc(
      'attendance_update_duty_roster',
      params: {'p_workplace_id': workplaceId, 'p_duty_roster': dutyRoster},
    );
  });

  Future<void> setDutyOnlyPunch({
    required String workplaceId,
    required bool dutyOnlyPunch,
  }) => _guard(() async {
    await _client.rpc(
      'attendance_set_duty_only_punch',
      params: {
        'p_workplace_id': workplaceId,
        'p_duty_only_punch': dutyOnlyPunch,
      },
    );
  });

  Future<String> createFolder(String name) => _guard(() async {
    final res = await _client.rpc(
      'attendance_create_folder',
      params: {'p_name': name},
    );
    return res.toString();
  });

  Future<void> setWorkplaceFolder({
    required String workplaceId,
    String? folderId,
  }) => _guard(() async {
    await _client.rpc(
      'attendance_set_workplace_folder',
      params: {'p_workplace_id': workplaceId, 'p_folder_id': folderId},
    );
  });

  Future<void> setMemberBaseSalary({
    required String workplaceId,
    required String profileId,
    required int baseSalaryTenge,
  }) => _guard(() async {
    await _client.rpc(
      'attendance_set_member_base_salary',
      params: {
        'p_workplace_id': workplaceId,
        'p_profile_id': profileId,
        'p_base_salary_tenge': baseSalaryTenge,
      },
    );
  });

  Future<String> upsertOvertime({
    required String workplaceId,
    required String profileId,
    required DateTime workDate,
    required int hours,
    String? clientRequestId,
  }) => _guard(() async {
    final res = await _client.rpc(
      'attendance_upsert_overtime',
      params: {
        'p_workplace_id': workplaceId,
        'p_profile_id': profileId,
        'p_work_date': _dateOnly(workDate),
        'p_hours': hours,
        'p_client_request_id': clientRequestId,
      },
    );
    return res.toString();
  });

  Future<void> setOvertimeStatus({
    required String entryId,
    required String status,
  }) => _guard(() async {
    await _client.rpc(
      'attendance_set_overtime_status',
      params: {'p_entry_id': entryId, 'p_status': status},
    );
  });

  Future<Map<String, dynamic>> analyticsOverview({
    required String workplaceId,
    required DateTime start,
    required DateTime end,
  }) => _guard(() async {
    final res = await _client.rpc(
      'attendance_analytics_overview',
      params: {
        'p_workplace_id': workplaceId,
        'p_start': _dateOnly(start),
        'p_end': _dateOnly(end),
      },
    );
    return Map<String, dynamic>.from(res as Map);
  });

  Future<String> timesheetCsv({
    required String workplaceId,
    required DateTime start,
    required DateTime end,
  }) => _guard(() async {
    final res = await _client.rpc(
      'attendance_timesheet_csv',
      params: {
        'p_workplace_id': workplaceId,
        'p_start': _dateOnly(start),
        'p_end': _dateOnly(end),
      },
    );
    return res?.toString() ?? '';
  });

  Future<String> requestPunchCorrection({
    required String punchId,
    String? note,
    DateTime? proposedPunchedAt,
  }) => _guard(() async {
    final res = await _client.rpc(
      'attendance_request_punch_correction',
      params: {
        'p_punch_id': punchId,
        'p_note': note,
        if (proposedPunchedAt != null)
          'p_proposed_punched_at': proposedPunchedAt.toUtc().toIso8601String(),
      },
    );
    return res.toString();
  });

  Future<void> resolvePunchCorrection({
    required String correctionId,
    required String status,
  }) => _guard(() async {
    await _client.rpc(
      'attendance_resolve_punch_correction',
      params: {'p_correction_id': correctionId, 'p_status': status},
    );
  });

  Future<List<AttendanceCorrectionRequest>> listPunchCorrections({
    required String workplaceId,
    String? status,
  }) => _guard(() async {
    final res = await _client.rpc(
      'attendance_list_corrections',
      params: {
        'p_workplace_id': workplaceId,
        if (status != null) 'p_status': status,
      },
    );
    final List rawList;
    if (res is List) {
      rawList = res;
    } else if (res is String) {
      final decoded = jsonDecode(res);
      rawList = decoded is List ? decoded : const [];
    } else {
      rawList = const [];
    }
    return [
      for (final raw in rawList)
        if (raw is Map)
          AttendanceCorrectionRequest.fromJson(Map<String, dynamic>.from(raw)),
    ];
  });

  static String _dateOnly(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

abstract final class AttendanceBootstrapMapper {
  static AttendanceSnapshot fromJson(
    Map<String, dynamic> json, {
    String? currentUserId,
  }) {
    final workplacesRaw = (json['workplaces'] as List?) ?? const [];
    final foldersRaw = (json['folders'] as List?) ?? const [];
    final membershipsRaw = (json['memberships'] as List?) ?? const [];
    final typesRaw = (json['punch_types'] as List?) ?? const [];
    final punchesRaw = (json['punches'] as List?) ?? const [];
    final absencesRaw = (json['absences'] as List?) ?? const [];
    final overtimeRaw = (json['overtime_entries'] as List?) ?? const [];

    final folders = foldersRaw
        .map((raw) {
          final m = Map<String, dynamic>.from(raw as Map);
          return AttendanceFolder(
            id: m['id']?.toString() ?? '',
            name: m['name']?.toString() ?? '',
          );
        })
        .where((f) => f.id.isNotEmpty)
        .toList(growable: false);

    final typesByWorkplace = <String, List<AttendanceCustomPunchConfig>>{};
    for (final raw in typesRaw) {
      final m = Map<String, dynamic>.from(raw as Map);
      final wid = m['workplace_id']?.toString() ?? '';
      final list = typesByWorkplace.putIfAbsent(wid, () => []);
      list.add(
        AttendanceCustomPunchConfig(
          id: m['id']?.toString(),
          label: m['label']?.toString() ?? '',
          scheduledTime: _parseTime(m['scheduled_time']?.toString()),
        ),
      );
    }

    final salariesByWorkplace = <String, Map<String, int>>{};
    for (final raw in membershipsRaw) {
      final m = Map<String, dynamic>.from(raw as Map);
      final wid = m['workplace_id']?.toString() ?? '';
      final pid = m['profile_id']?.toString() ?? '';
      if (wid.isEmpty || pid.isEmpty) continue;
      final salary = (m['base_salary_tenge'] as num?)?.toInt() ?? 0;
      salariesByWorkplace.putIfAbsent(wid, () => {})[pid] = salary;
    }

    final workplaces = workplacesRaw
        .map((raw) {
          final m = Map<String, dynamic>.from(raw as Map);
          final id = m['id']?.toString() ?? '';
          final payrollRaw = m['payroll_rules'];
          final dutyRaw = m['duty_roster'];
          return AttendanceWorkplace(
            id: id,
            name: m['name']?.toString() ?? '',
            folderId: m['folder_id']?.toString(),
            latitude: (m['latitude'] as num?)?.toDouble(),
            longitude: (m['longitude'] as num?)?.toDouble(),
            geofenceRadiusM: (m['geofence_radius_m'] as num?)?.toInt() ?? 150,
            clockInEnabled: m['clock_in_enabled'] as bool? ?? true,
            clockOutEnabled: m['clock_out_enabled'] as bool? ?? true,
            clockInScheduledTime: _parseTime(
              m['clock_in_scheduled']?.toString(),
            ),
            clockOutScheduledTime: _parseTime(
              m['clock_out_scheduled']?.toString(),
            ),
            customPunches: typesByWorkplace[id] ?? const [],
            isAdmin: m['is_admin'] as bool? ?? false,
            groupConversationId: m['group_conversation_id']?.toString(),
            payrollRules: AttendancePayrollRules.fromJson(
              payrollRaw is Map ? Map<String, dynamic>.from(payrollRaw) : null,
            ),
            dutyRoster: AttendanceDutyRoster.fromJson(
              dutyRaw is Map ? Map<String, dynamic>.from(dutyRaw) : null,
            ),
            dutyOnlyPunch: m['duty_only_punch'] as bool? ?? false,
            workerBaseSalaries: Map<String, int>.from(
              salariesByWorkplace[id] ?? const {},
            ),
          );
        })
        .toList(growable: false);

    final allMemberships = membershipsRaw
        .map((raw) => Map<String, dynamic>.from(raw as Map))
        .map(
          (m) => AttendanceMembership(
            id: m['id']?.toString(),
            workplaceId: m['workplace_id']?.toString() ?? '',
            workplaceName: m['workplace_name']?.toString() ?? '',
            profileId: m['profile_id']?.toString(),
            status: _membershipStatus(m['status']?.toString()),
            shiftOpen: m['shift_open'] as bool? ?? false,
            ackVersion: (m['ack_version'] as num?)?.toInt() ?? 0,
            configVersion: (m['config_version'] as num?)?.toInt() ?? 1,
            hasAttendanceWorkTag: m['has_attendance_work_tag'] as bool? ?? false,
          ),
        )
        .where((m) => m.status != AttendanceWorkerInviteStatus.declined)
        .toList(growable: false);

    final myMemberships = currentUserId == null
        ? allMemberships
        : allMemberships
              .where((m) => m.profileId == currentUserId)
              .toList(growable: false);

    final typeLabelById = <String, String>{};
    for (final raw in typesRaw) {
      final m = Map<String, dynamic>.from(raw as Map);
      final id = m['id']?.toString();
      if (id != null) typeLabelById[id] = m['label']?.toString() ?? '';
    }

    final punches = punchesRaw
        .map((raw) {
          final m = Map<String, dynamic>.from(raw as Map);
          final kind = m['punch_kind']?.toString() ?? 'clock_in';
          final typeId = m['punch_type_id']?.toString();
          final type = switch (kind) {
            'clock_out' => AttendancePunchType.clockOut,
            'custom' => AttendancePunchType(
              key: typeId ?? 'custom',
              labelRu: typeLabelById[typeId] ?? 'Отметка',
            ),
            _ => AttendancePunchType.clockIn,
          };
          return AttendancePunchRecord(
            id: m['id']?.toString() ?? '',
            workplaceId: m['workplace_id']?.toString() ?? '',
            workerId: m['profile_id']?.toString() ?? '',
            type: type,
            at:
                DateTime.tryParse(
                  m['punched_at']?.toString() ?? '',
                )?.toLocal() ??
                DateTime.now(),
            cancelled: m['cancelled_at'] != null,
            cancelComment: m['cancel_note']?.toString(),
          );
        })
        .toList(growable: false);

    final absences = absencesRaw
        .map((raw) {
          final m = Map<String, dynamic>.from(raw as Map);
          return AttendanceAbsenceEntry(
            id: m['id']?.toString() ?? '',
            workplaceId: m['workplace_id']?.toString() ?? '',
            workerId: m['profile_id']?.toString() ?? '',
            kind: AttendanceAbsenceKindX.fromKey(
              m['kind']?.toString() ?? 'day_off',
            ),
            startDate:
                DateTime.tryParse(m['start_date']?.toString() ?? '') ??
                DateTime.now(),
            endDate:
                DateTime.tryParse(m['end_date']?.toString() ?? '') ??
                DateTime.now(),
            note: m['note']?.toString(),
          );
        })
        .toList(growable: false);

    final overtimeEntries = overtimeRaw
        .map((raw) {
          final m = Map<String, dynamic>.from(raw as Map);
          final pid = m['profile_id']?.toString() ?? '';
          return AttendanceOvertimeEntry(
            id: m['id']?.toString() ?? '',
            workplaceId: m['workplace_id']?.toString() ?? '',
            workerId: pid,
            workerName: pid,
            date:
                DateTime.tryParse(m['work_date']?.toString() ?? '') ??
                DateTime.now(),
            hours: (m['hours'] as num?)?.toInt() ?? 0,
            status: AttendanceOvertimeStatusX.fromKey(m['status']?.toString()),
          );
        })
        .toList(growable: false);

    return AttendanceSnapshot(
      workplaces: workplaces,
      folders: folders,
      memberships: myMemberships,
      rosterMemberships: allMemberships,
      punchHistory: punches,
      absences: absences,
      overtimeEntries: overtimeEntries,
      fromRemote: true,
      mockInGeofence: false,
      mockGpsEnabled: false,
    );
  }

  static AttendanceWorkerInviteStatus _membershipStatus(String? raw) =>
      switch (raw) {
        'pending' => AttendanceWorkerInviteStatus.pending,
        'archived' => AttendanceWorkerInviteStatus.archived,
        'declined' => AttendanceWorkerInviteStatus.declined,
        _ => AttendanceWorkerInviteStatus.accepted,
      };

  static AttendanceDayTime? _parseTime(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final parts = raw.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return AttendanceDayTime(hour: h, minute: m);
  }
}
