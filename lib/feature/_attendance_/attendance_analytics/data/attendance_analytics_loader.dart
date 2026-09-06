import 'package:clover/feature/_attendance_/attendance_analytics/data/attendance_analytics.dart';
import 'package:clover/feature/_attendance_/attendance_analytics/data/models/attendance_analytics_models.dart';
import 'package:clover/feature/_attendance_/shared/data/attendance_context_store.dart';
import 'package:clover/feature/_attendance_/shared/data/attendance_remote_repository.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_absence.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_punch_record.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_punch_type.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_snapshot.dart';
import 'package:injectable/injectable.dart';

/// Loads period analytics: remote RPC punches/absences when online, else local snapshot.
@lazySingleton
class AttendanceAnalyticsLoader {
  AttendanceAnalyticsLoader(this._store, this._remote);

  final AttendanceContextStore _store;
  final AttendanceRemoteRepository _remote;

  Future<AttendanceAnalyticsOverview> loadOverview({
    required String workplaceId,
    required DateTime start,
    required DateTime end,
  }) async {
    final snap = _store.snapshot.value;
    if (snap == null) {
      return const AttendanceAnalyticsOverview(
        workers: [],
        totalMinutes: 0,
        avgMinutesPerWorker: 0,
        lateDaysTotal: 0,
        missedDaysTotal: 0,
      );
    }

    if (!_store.isRemote) {
      return AttendanceAnalytics.overview(
        snapshot: snap,
        workplaceId: workplaceId,
        start: start,
        end: end,
      );
    }

    try {
      final raw = await _remote.analyticsOverview(
        workplaceId: workplaceId,
        start: start,
        end: end,
      );
      final merged = _mergePeriod(snap, workplaceId, start, end, raw);
      return AttendanceAnalytics.overview(
        snapshot: merged,
        workplaceId: workplaceId,
        start: start,
        end: end,
      );
    } catch (_) {
      return AttendanceAnalytics.overview(
        snapshot: snap,
        workplaceId: workplaceId,
        start: start,
        end: end,
      );
    }
  }

  AttendanceSnapshot _mergePeriod(
    AttendanceSnapshot snapshot,
    String workplaceId,
    DateTime start,
    DateTime end,
    Map<String, dynamic> raw,
  ) {
    final rangeStart = AttendanceAnalytics.dayKey(start);
    final rangeEnd = AttendanceAnalytics.dayKey(end);
    final punches = _mapPunches(raw, workplaceId);
    final absences = _mapAbsences(raw, workplaceId);

    final keptPunches = snapshot.punchHistory.where((p) {
      if (p.workplaceId != workplaceId) return true;
      final d = AttendanceAnalytics.dayKey(p.at);
      return d.isBefore(rangeStart) || d.isAfter(rangeEnd);
    });
    final keptAbsences = snapshot.absences.where((a) {
      if (a.workplaceId != workplaceId) return true;
      final aStart = AttendanceAnalytics.dayKey(a.startDate);
      final aEnd = AttendanceAnalytics.dayKey(a.endDate);
      return aEnd.isBefore(rangeStart) || aStart.isAfter(rangeEnd);
    });

    return snapshot.copyWith(
      punchHistory: [...keptPunches, ...punches],
      absences: [...keptAbsences, ...absences],
    );
  }

  List<AttendancePunchRecord> _mapPunches(Map<String, dynamic> raw, String workplaceId) {
    final list = (raw['punches'] as List?) ?? const [];
    return [
      for (final item in list)
        if (item is Map)
          AttendancePunchRecord(
            id: item['id']?.toString() ?? '',
            workplaceId: workplaceId,
            workerId: item['profile_id']?.toString() ?? '',
            type: switch (item['punch_kind']?.toString()) {
              'clock_out' => AttendancePunchType.clockOut,
              'custom' => AttendancePunchType(
                  key: item['punch_type_id']?.toString() ?? 'custom',
                  labelRu: 'Отметка',
                ),
              _ => AttendancePunchType.clockIn,
            },
            at: DateTime.tryParse(item['punched_at']?.toString() ?? '')?.toLocal() ?? DateTime.now(),
            cancelled: item['cancelled_at'] != null,
          ),
    ];
  }

  List<AttendanceAbsenceEntry> _mapAbsences(Map<String, dynamic> raw, String workplaceId) {
    final list = (raw['absences'] as List?) ?? const [];
    return [
      for (final item in list)
        if (item is Map)
          AttendanceAbsenceEntry(
            id: item['id']?.toString() ?? '',
            workplaceId: workplaceId,
            workerId: item['profile_id']?.toString() ?? '',
            kind: AttendanceAbsenceKindX.fromKey(item['kind']?.toString() ?? 'day_off'),
            startDate: DateTime.tryParse(item['start_date']?.toString() ?? '') ?? DateTime.now(),
            endDate: DateTime.tryParse(item['end_date']?.toString() ?? '') ?? DateTime.now(),
            note: item['note']?.toString(),
          ),
    ];
  }
}
