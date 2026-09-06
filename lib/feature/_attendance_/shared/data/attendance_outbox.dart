import 'dart:convert';

import 'package:clover/core/storage/domain/repositories/i_app_storage.dart';
import 'package:clover/feature/_attendance_/shared/data/attendance_error.dart';
import 'package:clover/feature/_attendance_/shared/data/attendance_remote_repository.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_absence.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_custom_punch_config.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_day_time.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

/// Kind of mutation queued for offline flush.
enum AttendanceOutboxKind {
  payrollSettings,
  dutyRoster,
  memberBaseSalary,
  overtimeUpsert,
  overtimeStatus,
  punch,
  punchCancel,
  absence,
  geofence,
  punchConfig,
}

/// Result of a persist attempt that may have been queued offline.
enum AttendancePersistResult {
  /// Written to server (or local mock store).
  synced,
  /// Optimistic local patch + queued for flush.
  queued,
}

/// One pending attendance mutation (idempotent where server supports client ids).
class AttendanceOutboxItem {
  const AttendanceOutboxItem({
    required this.id,
    required this.kind,
    required this.payload,
    required this.createdAt,
    this.attempts = 0,
  });

  final String id;
  final AttendanceOutboxKind kind;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final int attempts;

  AttendanceOutboxItem copyWith({int? attempts}) {
    return AttendanceOutboxItem(
      id: id,
      kind: kind,
      payload: payload,
      createdAt: createdAt,
      attempts: attempts ?? this.attempts,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind.name,
        'payload': payload,
        'created_at': createdAt.toUtc().toIso8601String(),
        'attempts': attempts,
      };

  static AttendanceOutboxItem? fromJson(Map<String, dynamic> json) {
    final kindName = json['kind']?.toString();
    final kind = AttendanceOutboxKind.values.where((k) => k.name == kindName).firstOrNull;
    if (kind == null) return null;
    final id = json['id']?.toString() ?? '';
    if (id.isEmpty) return null;
    final payloadRaw = json['payload'];
    final payload = payloadRaw is Map ? Map<String, dynamic>.from(payloadRaw) : <String, dynamic>{};
    return AttendanceOutboxItem(
      id: id,
      kind: kind,
      payload: payload,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '')?.toUtc() ?? DateTime.now().toUtc(),
      attempts: (json['attempts'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Local outbox for attendance mutations when offline / network fails.
@lazySingleton
class AttendanceOutbox {
  AttendanceOutbox(this._storage, this._remote);

  final IAppStorage _storage;
  final AttendanceRemoteRepository _remote;

  final ValueNotifier<int> pendingCount = ValueNotifier(0);

  static String _key(String userId) => 'resource_attendance_outbox_$userId';

  bool _flushing = false;

  Future<List<AttendanceOutboxItem>> _load(String userId) async {
    final raw = await _storage.read<String>(key: _key(userId));
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      final out = <AttendanceOutboxItem>[];
      for (final e in list) {
        if (e is! Map) continue;
        final item = AttendanceOutboxItem.fromJson(Map<String, dynamic>.from(e));
        if (item != null) out.add(item);
      }
      return out;
    } catch (_) {
      return const [];
    }
  }

  Future<void> _save(String userId, List<AttendanceOutboxItem> items) async {
    await _storage.write<String>(
      key: _key(userId),
      value: jsonEncode([for (final i in items) i.toJson()]),
    );
    pendingCount.value = items.length;
  }

  Future<void> refreshCount([String? userId]) async {
    final uid = userId ?? _remote.currentUserId;
    if (uid == null || uid.isEmpty) {
      pendingCount.value = 0;
      return;
    }
    final items = await _load(uid);
    pendingCount.value = items.length;
  }

  Future<void> enqueue(AttendanceOutboxItem item, {String? userId}) async {
    final uid = userId ?? _remote.currentUserId;
    if (uid == null || uid.isEmpty) return;
    final items = [...await _load(uid)];
    final idx = items.indexWhere((e) => e.id == item.id);
    if (idx >= 0) {
      items[idx] = item;
    } else {
      items.add(item);
    }
    await _save(uid, items);
  }

  Future<void> clearForUser(String userId) async {
    await _storage.delete(key: _key(userId));
    pendingCount.value = 0;
  }

  /// Flush pending mutations. Returns number flushed.
  Future<int> flush({String? userId}) async {
    if (_flushing) return 0;
    final uid = userId ?? _remote.currentUserId;
    if (uid == null || uid.isEmpty) return 0;

    _flushing = true;
    try {
      final items = await _load(uid);
      if (items.isEmpty) {
        pendingCount.value = 0;
        return 0;
      }

      final remaining = <AttendanceOutboxItem>[];
      var flushed = 0;

      for (final item in items) {
        try {
          await _apply(item);
          flushed++;
        } on AttendanceException catch (e) {
          if (e.isRetriableNetwork) {
            remaining.add(item.copyWith(attempts: item.attempts + 1));
          }
          // Non-retriable: drop (server rejected / stale).
        } catch (_) {
          remaining.add(item.copyWith(attempts: item.attempts + 1));
        }
      }

      await _save(uid, remaining);
      return flushed;
    } finally {
      _flushing = false;
    }
  }

  Future<void> _apply(AttendanceOutboxItem item) async {
    final p = item.payload;
    switch (item.kind) {
      case AttendanceOutboxKind.payrollSettings:
        await _remote.updatePayrollSettings(
          workplaceId: p['workplace_id'] as String,
          payrollRules: Map<String, dynamic>.from(p['payroll_rules'] as Map),
        );
      case AttendanceOutboxKind.dutyRoster:
        await _remote.updateDutyRoster(
          workplaceId: p['workplace_id'] as String,
          dutyRoster: Map<String, dynamic>.from(p['duty_roster'] as Map),
        );
      case AttendanceOutboxKind.memberBaseSalary:
        await _remote.setMemberBaseSalary(
          workplaceId: p['workplace_id'] as String,
          profileId: p['profile_id'] as String,
          baseSalaryTenge: (p['base_salary_tenge'] as num).toInt(),
        );
      case AttendanceOutboxKind.overtimeUpsert:
        await _remote.upsertOvertime(
          workplaceId: p['workplace_id'] as String,
          profileId: p['profile_id'] as String,
          workDate: DateTime.parse(p['work_date'] as String),
          hours: (p['hours'] as num).toInt(),
          clientRequestId: p['client_request_id'] as String?,
        );
      case AttendanceOutboxKind.overtimeStatus:
        await _remote.setOvertimeStatus(
          entryId: p['entry_id'] as String,
          status: p['status'] as String,
        );
      case AttendanceOutboxKind.punch:
        await _remote.submitPunch(
          workplaceId: p['workplace_id'] as String,
          punchKind: p['punch_kind'] as String,
          lat: (p['lat'] as num).toDouble(),
          lng: (p['lng'] as num).toDouble(),
          punchTypeId: p['punch_type_id'] as String?,
          clientPunchId: p['client_punch_id'] as String?,
          punchedAt: p['punched_at'] != null ? DateTime.tryParse(p['punched_at'] as String) : null,
        );
      case AttendanceOutboxKind.punchCancel:
        await _remote.cancelPunch(
          punchId: p['punch_id'] as String,
          note: p['note'] as String?,
        );
      case AttendanceOutboxKind.absence:
        await _remote.upsertAbsence(
          workplaceId: p['workplace_id'] as String,
          profileId: p['profile_id'] as String,
          kind: AttendanceAbsenceKindX.fromKey(p['kind'] as String? ?? 'day_off'),
          startDate: DateTime.parse(p['start_date'] as String),
          endDate: DateTime.parse(p['end_date'] as String),
          note: p['note'] as String?,
          absenceId: p['absence_id'] as String?,
        );
      case AttendanceOutboxKind.geofence:
        await _remote.updateWorkplaceSettings(
          workplaceId: p['workplace_id'] as String,
          lat: (p['lat'] as num).toDouble(),
          lng: (p['lng'] as num).toDouble(),
          geofenceRadiusM: (p['geofence_radius_m'] as num).toInt(),
        );
      case AttendanceOutboxKind.punchConfig:
        await _remote.updateWorkplaceSettings(
          workplaceId: p['workplace_id'] as String,
          clockInEnabled: p['clock_in_enabled'] as bool?,
          clockOutEnabled: p['clock_out_enabled'] as bool?,
          clockInScheduled: p['clock_in_scheduled'] as String?,
          clockOutScheduled: p['clock_out_scheduled'] as String?,
        );
        final customsRaw = p['custom_punches'];
        final customs = <AttendanceCustomPunchConfig>[];
        if (customsRaw is List) {
          for (final e in customsRaw) {
            if (e is! Map) continue;
            final m = Map<String, dynamic>.from(e);
            customs.add(
              AttendanceCustomPunchConfig(
                id: m['id']?.toString(),
                label: m['label']?.toString() ?? '',
                scheduledTime: _parseDayTime(m['scheduled']?.toString()),
              ),
            );
          }
        }
        await _remote.replaceCustomPunchTypes(
          workplaceId: p['workplace_id'] as String,
          customPunches: customs,
        );
    }
  }
}

AttendanceDayTime? _parseDayTime(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  final parts = raw.split(':');
  if (parts.length < 2) return null;
  final h = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  if (h == null || m == null) return null;
  return AttendanceDayTime(hour: h, minute: m);
}
