import 'package:clover/feature/_attendance_/shared/data/attendance_error.dart';
import 'package:clover/feature/_attendance_/shared/data/attendance_workers_mock.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_absence.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_custom_punch_config.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_day_time.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_membership.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_profile_hit.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_punch_record.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_punch_type.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_snapshot.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_workplace.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Concrete Supabase API for attendance core (bootstrap / invite / punch).
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
    var builder = _client.from('profiles').select('id, username, full_name, avatar_url').neq('id', uid);

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

  Future<AttendanceSnapshot> _enrichWorkerLabels(AttendanceSnapshot snap) async {
    final ids = <String>{
      for (final m in snap.rosterMemberships)
        if (m.profileId != null && m.profileId!.isNotEmpty) m.profileId!,
    };
    if (ids.isEmpty) return snap;

    final res = await _client.from('profiles').select('id, username, full_name').inFilter('id', ids.toList());
    final names = <String, String>{};
    final usernames = <String, String>{};
    for (final raw in res as List) {
      final row = Map<String, dynamic>.from(raw as Map);
      final id = row['id']?.toString() ?? '';
      if (id.isEmpty) continue;
      final username = row['username']?.toString().trim() ?? '';
      final fullName = row['full_name']?.toString().trim() ?? '';
      final handle = username.isEmpty ? '' : (username.startsWith('@') ? username : '@$username');
      names[id] = fullName.isNotEmpty ? fullName : (handle.isNotEmpty ? handle : id);
      usernames[id] = handle;
    }
    if (names.isEmpty) return snap;
    return snap.copyWith(profileDisplayNames: names, profileUsernames: usernames);
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

  Future<String> inviteMember({required String workplaceId, required String profileId}) => _guard(() async {
    final res = await _client.rpc(
      'attendance_invite_member',
      params: {'p_workplace_id': workplaceId, 'p_profile_id': profileId},
    );
    return res.toString();
  });

  Future<void> acceptInvite(String membershipId) => _guard(() async {
    await _client.rpc('attendance_accept_invite', params: {'p_membership_id': membershipId});
  });

  Future<void> rejectInvite(String membershipId) => _guard(() async {
    await _client.rpc('attendance_reject_invite', params: {'p_membership_id': membershipId});
  });

  Future<void> archiveMember(String membershipId) => _guard(() async {
    await _client.rpc('attendance_archive_member', params: {'p_membership_id': membershipId});
  });

  Future<void> reinviteMember(String membershipId) => _guard(() async {
    await _client.rpc('attendance_reinvite_member', params: {'p_membership_id': membershipId});
  });

  Future<void> ackConfig(String workplaceId) => _guard(() async {
    await _client.rpc('attendance_ack_config', params: {'p_workplace_id': workplaceId});
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
        if (punchedAt != null) 'p_punched_at': punchedAt.toUtc().toIso8601String(),
      },
    );
    return res.toString();
  });

  Future<void> cancelPunch({required String punchId, String? note}) => _guard(() async {
    await _client.rpc('cancel_attendance_punch', params: {'p_punch_id': punchId, 'p_note': note});
  });

  /// Owner upsert of custom punch types via PostgREST (RLS).
  Future<void> replaceCustomPunchTypes({
    required String workplaceId,
    required List<AttendanceCustomPunchConfig> customPunches,
  }) => _guard(() async {
    final existing = await _client
        .from('attendance_punch_type_defs')
        .select('id')
        .eq('workplace_id', workplaceId)
        .eq('is_active', true);
    final keepIds = customPunches.map((e) => e.id).whereType<String>().toSet();
    for (final row in existing as List) {
      final id = Map<String, dynamic>.from(row as Map)['id']?.toString();
      if (id != null && !keepIds.contains(id)) {
        await _client.from('attendance_punch_type_defs').update({'is_active': false}).eq('id', id);
      }
    }
    var order = 0;
    for (final c in customPunches) {
      final scheduled = c.scheduledTime == null
          ? null
          : '${c.scheduledTime!.hour.toString().padLeft(2, '0')}:'
                '${c.scheduledTime!.minute.toString().padLeft(2, '0')}:00';
      if (c.id != null) {
        await _client
            .from('attendance_punch_type_defs')
            .update({'label': c.label, 'scheduled_time': scheduled, 'sort_order': order, 'is_active': true})
            .eq('id', c.id!);
      } else {
        await _client.from('attendance_punch_type_defs').insert({
          'workplace_id': workplaceId,
          'label': c.label,
          'scheduled_time': scheduled,
          'sort_order': order,
          'is_active': true,
        });
      }
      order++;
    }
    final row = await _client
        .from('attendance_workplaces')
        .select('config_version')
        .eq('id', workplaceId)
        .single();
    final ver = (row['config_version'] as num?)?.toInt() ?? 1;
    await _client.from('attendance_workplaces').update({'config_version': ver + 1}).eq('id', workplaceId);
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

  static String _dateOnly(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

abstract final class AttendanceBootstrapMapper {
  static AttendanceSnapshot fromJson(Map<String, dynamic> json, {String? currentUserId}) {
    final workplacesRaw = (json['workplaces'] as List?) ?? const [];
    final membershipsRaw = (json['memberships'] as List?) ?? const [];
    final typesRaw = (json['punch_types'] as List?) ?? const [];
    final punchesRaw = (json['punches'] as List?) ?? const [];
    final absencesRaw = (json['absences'] as List?) ?? const [];

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

    final workplaces = workplacesRaw
        .map((raw) {
          final m = Map<String, dynamic>.from(raw as Map);
          final id = m['id']?.toString() ?? '';
          return AttendanceWorkplace(
            id: id,
            name: m['name']?.toString() ?? '',
            folderId: m['folder_id']?.toString(),
            latitude: (m['latitude'] as num?)?.toDouble(),
            longitude: (m['longitude'] as num?)?.toDouble(),
            geofenceRadiusM: (m['geofence_radius_m'] as num?)?.toInt() ?? 150,
            clockInEnabled: m['clock_in_enabled'] as bool? ?? true,
            clockOutEnabled: m['clock_out_enabled'] as bool? ?? true,
            clockInScheduledTime: _parseTime(m['clock_in_scheduled']?.toString()),
            clockOutScheduledTime: _parseTime(m['clock_out_scheduled']?.toString()),
            customPunches: typesByWorkplace[id] ?? const [],
            isAdmin: m['is_admin'] as bool? ?? false,
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
          ),
        )
        .where((m) => m.status != AttendanceWorkerInviteStatus.declined)
        .toList(growable: false);

    final myMemberships = currentUserId == null
        ? allMemberships
        : allMemberships.where((m) => m.profileId == currentUserId).toList(growable: false);

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
            at: DateTime.tryParse(m['punched_at']?.toString() ?? '')?.toLocal() ?? DateTime.now(),
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
            kind: AttendanceAbsenceKindX.fromKey(m['kind']?.toString() ?? 'day_off'),
            startDate: DateTime.tryParse(m['start_date']?.toString() ?? '') ?? DateTime.now(),
            endDate: DateTime.tryParse(m['end_date']?.toString() ?? '') ?? DateTime.now(),
            note: m['note']?.toString(),
          );
        })
        .toList(growable: false);

    return AttendanceSnapshot(
      workplaces: workplaces,
      memberships: myMemberships,
      rosterMemberships: allMemberships,
      punchHistory: punches,
      absences: absences,
      fromRemote: true,
      mockInGeofence: true,
      mockGpsEnabled: true,
    );
  }

  static AttendanceWorkerInviteStatus _membershipStatus(String? raw) => switch (raw) {
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
