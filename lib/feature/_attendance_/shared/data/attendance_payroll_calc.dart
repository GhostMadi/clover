import 'package:clover/feature/_attendance_/shared/data/models/attendance_worker.dart';
import 'package:clover/feature/_attendance_/attendance_analytics/data/attendance_analytics.dart';
import 'package:clover/feature/_attendance_/attendance_analytics/data/models/attendance_analytics_models.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_absence.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_payroll_models.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_snapshot.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_workplace.dart';

/// Offline/demo fallback: оценка ЗП из локального snapshot.
/// Remote path использует `attendance_payroll_preview` RPC.
abstract final class AttendancePayrollCalc {
  static String periodLabel([DateTime? now]) {
    final n = now ?? DateTime.now();
    const months = [
      'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
      'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь',
    ];
    return '${months[n.month - 1]} ${n.year}';
  }

  static List<AttendanceWorkerPayroll> forWorkplace(
    AttendanceWorkplace workplace, {
    required AttendanceSnapshot snapshot,
    DateTime? periodStart,
    DateTime? periodEnd,
  }) {
    final now = AttendanceAnalytics.today;
    final start = periodStart ?? DateTime(now.year, now.month, 1);
    final end = periodEnd ?? now;
    final workers = snapshot.workersFor(workplace.id).where((w) => w.isAccepted);
    return workers
        .map((w) => _rowFor(workplace, w, snapshot, start: start, end: end))
        .toList(growable: false);
  }

  static AttendancePayrollTeamSummary teamSummary(
    AttendanceWorkplace workplace, {
    required AttendanceSnapshot snapshot,
    DateTime? periodStart,
    DateTime? periodEnd,
  }) {
    final rows = forWorkplace(
      workplace,
      snapshot: snapshot,
      periodStart: periodStart,
      periodEnd: periodEnd,
    );
    return AttendancePayrollTeamSummary.fromRows(periodLabel: periodLabel(), rows: rows);
  }

  static int defaultBaseSalary(String workerId) => 250000;

  static AttendanceWorkerPayroll _rowFor(
    AttendanceWorkplace workplace,
    AttendanceWorkerListItem worker,
    AttendanceSnapshot snapshot, {
    required DateTime start,
    required DateTime end,
  }) {
    final rules = workplace.payrollRules;
    final baseSalary = workplace.workerBaseSalaries[worker.id] ?? defaultBaseSalary(worker.id);
    final otHours = snapshot.approvedOvertimeHours(workplaceId: workplace.id, workerId: worker.id);

    final formalAbsences = snapshot.absences
        .where((a) => a.workplaceId == workplace.id && a.workerId == worker.id)
        .toList();
    final hasFormalAbsence = formalAbsences.isNotEmpty;
    final absenceKinds = formalAbsences.map((a) => a.kind.key).toSet().join(',');

    final analytics = AttendanceAnalytics.worker(
      snapshot: snapshot,
      workplaceId: workplace.id,
      workerId: worker.id,
      displayName: worker.displayName,
      username: worker.username,
      start: start,
      end: end,
      workplace: workplace,
    );

    var lateMinutesTotal = 0;
    var lateDays = 0;
    var absentDays = 0;
    var partialDays = 0;
    if (analytics != null) {
      for (final day in analytics.daysByKey.values) {
        if (day.status == AttendanceDayStatus.late) {
          lateDays++;
          lateMinutesTotal += day.lateMinutes;
        } else if (day.status == AttendanceDayStatus.absent && !hasFormalAbsence) {
          absentDays++;
        } else if (day.status == AttendanceDayStatus.partial) {
          partialDays++;
        }
      }
    }

    final lines = <AttendancePayrollLineItem>[
      if (rules.lateDeductsPay && lateMinutesTotal > 0)
        AttendancePayrollLineItem.fromJson({
          'label': 'late',
          'detail': '${rules.lateDeductPerMinute}|$lateMinutesTotal|$lateDays',
          'amount': -(rules.lateDeductPerMinute * lateMinutesTotal),
          'kind': 'deduction',
        }),
      if (rules.absenceDeductsPay && absentDays > 0)
        AttendancePayrollLineItem.fromJson({
          'label': 'missed_shift',
          'detail': '${rules.absenceDeductPerDay}|$absentDays',
          'amount': -(rules.absenceDeductPerDay * absentDays),
          'kind': 'deduction',
        }),
      if (hasFormalAbsence)
        AttendancePayrollLineItem.fromJson({
          'label': 'absence_recorded',
          'detail': absenceKinds,
          'amount': 0,
          'kind': 'base',
        }),
      if (rules.partialDayDeductsPay && partialDays > 0)
        AttendancePayrollLineItem.fromJson({
          'label': 'partial_day',
          'detail': '${rules.partialDayDeductPercent}|$partialDays',
          'amount': -(baseSalary ~/
                  22 *
                  rules.partialDayDeductPercent /
                  100 *
                  partialDays)
              .round(),
          'kind': 'deduction',
        }),
      if (rules.overtimeAddsPay && otHours > 0)
        AttendancePayrollLineItem.fromJson({
          'label': 'overtime_approved',
          'detail': '${rules.overtimeBonusPerHour}|$otHours',
          'amount': rules.overtimeBonusPerHour * otHours,
          'kind': 'bonus',
        }),
    ];

    return AttendanceWorkerPayroll(
      workerId: worker.id,
      displayName: worker.displayName,
      username: worker.username,
      baseSalary: baseSalary,
      lines: lines,
    );
  }
}
