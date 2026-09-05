import 'package:clover/feature/_attendance_/shared/data/attendance_workers_mock.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_absence.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_payroll_models.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_snapshot.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_workplace.dart';

abstract final class AttendancePayrollMock {
  static const periodLabel = 'Сентябрь 2026';

  static List<AttendanceWorkerPayroll> forWorkplace(
    AttendanceWorkplace workplace, {
    AttendanceSnapshot? snapshot,
  }) {
    final workers = snapshot != null
        ? snapshot.workersFor(workplace.id).where((w) => w.isAccepted)
        : AttendanceWorkersMock.forWorkplace(workplace.id).where((w) => w.isAccepted);
    return workers.map((w) => _rowFor(workplace, w, snapshot)).toList(growable: false);
  }

  static AttendancePayrollTeamSummary teamSummary(
    AttendanceWorkplace workplace, {
    AttendanceSnapshot? snapshot,
  }) {
    final rows = forWorkplace(workplace, snapshot: snapshot);
    return AttendancePayrollTeamSummary.fromRows(periodLabel: periodLabel, rows: rows);
  }

  static int defaultBaseSalary(String workerId) => switch (workerId) {
        'worker_you' => 350000,
        'worker_ivan' => 280000,
        'worker_aidana' => 220000,
        _ => 250000,
      };

  static AttendanceWorkerPayroll _rowFor(
    AttendanceWorkplace workplace,
    AttendanceWorkerListItem worker,
    AttendanceSnapshot? snapshot,
  ) {
    final rules = workplace.payrollRules;
    final baseSalary = workplace.workerBaseSalaries[worker.id] ?? defaultBaseSalary(worker.id);
    // Только утверждённая переработка попадает в ЗП.
    final otHours = snapshot?.approvedOvertimeHours(workplaceId: workplace.id, workerId: worker.id) ?? 0;
    final formalAbsences = snapshot?.absences
            .where((a) => a.workplaceId == workplace.id && a.workerId == worker.id)
            .toList() ??
        const [];
    final hasFormalAbsence = formalAbsences.isNotEmpty;
    final absenceKinds = formalAbsences.map((a) => a.kind.labelRu).toSet().join(', ');

    final lines = <AttendancePayrollLineItem>[
      if (rules.lateDeductsPay && worker.id == 'worker_you')
        AttendancePayrollLineItem(
          label: 'Опоздания',
          detail: '${rules.lateDeductPerMinute} ₸ × 90 мин · 3 раза',
          amount: rules.lateDeductPerMinute * 90,
          kind: AttendancePayrollLineKind.deduction,
        ),
      if (rules.lateDeductsPay && worker.id == 'worker_aidana')
        AttendancePayrollLineItem(
          label: 'Опоздания',
          detail: '${rules.lateDeductPerMinute} ₸ × 45 мин · 2 раза',
          amount: rules.lateDeductPerMinute * 45,
          kind: AttendancePayrollLineKind.deduction,
        ),
      // Пропуск смены — только если нет оформленного отсутствия (absence overrides miss).
      if (rules.absenceDeductsPay && worker.id == 'worker_ivan' && !hasFormalAbsence)
        AttendancePayrollLineItem(
          label: 'Пропуск смены',
          detail: '${rules.absenceDeductPerDay} ₸ × 1 день',
          amount: rules.absenceDeductPerDay,
          kind: AttendancePayrollLineKind.deduction,
        ),
      if (hasFormalAbsence)
        AttendancePayrollLineItem(
          label: 'Отсутствие оформлено',
          detail: '$absenceKinds — не штраф за пропуск',
          amount: 0,
          kind: AttendancePayrollLineKind.base,
        ),
      if (rules.partialDayDeductsPay && worker.id == 'worker_ivan')
        AttendancePayrollLineItem(
          label: 'Неполный день',
          detail: '${rules.partialDayDeductPercent}% от дневной ставки · 1 раз',
          amount: (baseSalary ~/ 22 * rules.partialDayDeductPercent / 100).round(),
          kind: AttendancePayrollLineKind.deduction,
        ),
      if (rules.overtimeAddsPay && otHours > 0)
        AttendancePayrollLineItem(
          label: 'Переработка (утверждено)',
          detail: '${rules.overtimeBonusPerHour} ₸ × $otHours ч',
          amount: rules.overtimeBonusPerHour * otHours,
          kind: AttendancePayrollLineKind.bonus,
        ),
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
