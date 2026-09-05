import 'package:clover/feature/_attendance_/attendance_analytics/data/models/attendance_analytics_models.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_absence.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_punch_record.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_snapshot.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_workplace.dart';

/// Аналитика из snapshot (punches / absences / workers) — без mock-паттернов.
abstract final class AttendanceAnalytics {
  static DateTime dayKey(DateTime value) => DateTime(value.year, value.month, value.day);

  static DateTime get today => dayKey(DateTime.now());

  static String _hhmm(DateTime at) =>
      '${at.hour.toString().padLeft(2, '0')}:${at.minute.toString().padLeft(2, '0')}';

  static AttendanceAnalyticsOverview overview({
    required AttendanceSnapshot snapshot,
    required String workplaceId,
    required DateTime start,
    required DateTime end,
  }) {
    final workplace = snapshot.workplaceById(workplaceId);
    final workers = snapshot.workersFor(workplaceId).where((w) => w.isAccepted).toList(growable: false);
    final built = workers
        .map(
          (w) => worker(
            snapshot: snapshot,
            workplaceId: workplaceId,
            workerId: w.id,
            displayName: w.displayName,
            username: w.username,
            start: start,
            end: end,
            workplace: workplace,
          ),
        )
        .whereType<AttendanceAnalyticsWorker>()
        .toList(growable: false);

    final total = built.fold<int>(0, (sum, w) => sum + w.totalMinutes);
    final avg = built.isEmpty ? 0 : total ~/ built.length;
    final late = built.fold<int>(0, (sum, w) => sum + w.lateDays);
    final missed = built.fold<int>(0, (sum, w) => sum + w.missedDays);
    built.sort((a, b) => b.totalMinutes.compareTo(a.totalMinutes));

    return AttendanceAnalyticsOverview(
      workers: built,
      totalMinutes: total,
      avgMinutesPerWorker: avg,
      lateDaysTotal: late,
      missedDaysTotal: missed,
    );
  }

  static AttendanceAnalyticsWorker? worker({
    required AttendanceSnapshot snapshot,
    required String workplaceId,
    required String workerId,
    required DateTime start,
    required DateTime end,
    String? displayName,
    String? username,
    AttendanceWorkplace? workplace,
  }) {
    final listItem = snapshot.workersFor(workplaceId).where((w) => w.id == workerId).firstOrNull;
    final name = displayName ?? listItem?.displayName ?? _shortId(workerId);
    final nick = username ?? listItem?.username ?? '';
    final wp = workplace ?? snapshot.workplaceById(workplaceId);

    final rangeStart = dayKey(start);
    final rangeEnd = dayKey(end);
    final absences = snapshot.absences.where(
      (a) => a.workplaceId == workplaceId && a.workerId == workerId,
    );
    final punches = snapshot.punchHistory
        .where((p) => p.workplaceId == workplaceId && p.workerId == workerId && !p.cancelled)
        .toList(growable: false);

    final days = <DateTime, AttendanceWorkerDayRecord>{};
    var total = 0;
    var worked = 0;
    var late = 0;
    var missed = 0;

    for (var d = rangeStart; !d.isAfter(rangeEnd); d = d.add(const Duration(days: 1))) {
      final key = dayKey(d);
      final record = _dayRecord(
        key: key,
        punches: punches,
        absences: absences,
        workplace: wp,
        today: today,
      );
      days[key] = record;

      total += record.totalMinutes;
      if (record.status == AttendanceDayStatus.full ||
          record.status == AttendanceDayStatus.late ||
          record.status == AttendanceDayStatus.partial) {
        worked++;
      }
      if (record.status == AttendanceDayStatus.late) late++;
      if (record.status == AttendanceDayStatus.absent || record.status == AttendanceDayStatus.partial) {
        missed++;
      }
    }

    return AttendanceAnalyticsWorker(
      id: workerId,
      displayName: name,
      username: nick,
      totalMinutes: total,
      daysWorked: worked,
      lateDays: late,
      missedDays: missed,
      daysByKey: days,
    );
  }

  static AttendanceWorkerDayRecord _dayRecord({
    required DateTime key,
    required List<AttendancePunchRecord> punches,
    required Iterable<AttendanceAbsenceEntry> absences,
    required AttendanceWorkplace? workplace,
    required DateTime today,
  }) {
    if (key.isAfter(today)) {
      return AttendanceWorkerDayRecord(date: key, status: AttendanceDayStatus.off, totalMinutes: 0);
    }

    if (absences.any((a) => a.covers(key))) {
      return AttendanceWorkerDayRecord(date: key, status: AttendanceDayStatus.excused, totalMinutes: 0);
    }

    final dayPunches = punches.where((p) => dayKey(p.at) == key).toList(growable: false)
      ..sort((a, b) => a.at.compareTo(b.at));

    if (dayPunches.isEmpty) {
      if (key.weekday == DateTime.saturday || key.weekday == DateTime.sunday) {
        return AttendanceWorkerDayRecord(date: key, status: AttendanceDayStatus.off, totalMinutes: 0);
      }
      return AttendanceWorkerDayRecord(date: key, status: AttendanceDayStatus.absent, totalMinutes: 0);
    }

    final labels = dayPunches
        .map(
          (p) => AttendanceDayPunch(
            timeLabel: _hhmm(p.at),
            label: p.type.labelRu,
          ),
        )
        .toList(growable: false);

    DateTime? firstIn;
    DateTime? lastOut;
    for (final p in dayPunches) {
      if (p.type.isClockIn && firstIn == null) firstIn = p.at;
      if (p.type.isClockOut) lastOut = p.at;
    }

    var minutes = 0;
    if (firstIn != null && lastOut != null && !lastOut.isBefore(firstIn)) {
      minutes = lastOut.difference(firstIn).inMinutes;
    }

    final scheduled = workplace?.clockInScheduledTime;
    var status = AttendanceDayStatus.full;
    if (firstIn != null && lastOut == null) {
      status = AttendanceDayStatus.partial;
    } else if (firstIn != null && scheduled != null) {
      final scheduledAt = DateTime(key.year, key.month, key.day, scheduled.hour, scheduled.minute);
      if (firstIn.isAfter(scheduledAt.add(const Duration(minutes: 5)))) {
        status = AttendanceDayStatus.late;
      }
    }

    return AttendanceWorkerDayRecord(
      date: key,
      status: status,
      totalMinutes: minutes,
      punches: labels,
    );
  }

  static String _shortId(String id) => id.length > 8 ? '${id.substring(0, 8)}…' : id;
}

extension _FirstOrNullAnalytics<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    if (!it.moveNext()) return null;
    return it.current;
  }
}
