import 'package:clover/feature/_attendance_/attendance_analytics/data/models/attendance_analytics_models.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_absence.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_correction_request.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_overtime_entry.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_punch_type.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_worker.dart';
import 'package:clover/l10n/app_localizations.dart';

extension AttendanceSystemPunchCodeL10n on AttendanceSystemPunchCode {
  String label(AppLocalizations l10n) => switch (this) {
        AttendanceSystemPunchCode.clockIn => l10n.attendance_punch_clock_in,
        AttendanceSystemPunchCode.clockOut => l10n.attendance_punch_clock_out,
      };
}

extension AttendancePunchTypeL10n on AttendancePunchType {
  String label(AppLocalizations l10n) {
    final code = systemCode;
    if (code != null) return code.label(l10n);
    return labelRu;
  }
}

extension AttendanceDayStatusL10n on AttendanceDayStatus {
  String label(AppLocalizations l10n) => switch (this) {
        AttendanceDayStatus.full => l10n.attendance_day_status_full,
        AttendanceDayStatus.late => l10n.attendance_day_status_late,
        AttendanceDayStatus.partial => l10n.attendance_day_status_partial,
        AttendanceDayStatus.absent => l10n.attendance_day_status_absent,
        AttendanceDayStatus.excused => l10n.attendance_day_status_excused,
        AttendanceDayStatus.off => l10n.attendance_day_status_off,
      };

  String shortLabel(AppLocalizations l10n) => switch (this) {
        AttendanceDayStatus.full => l10n.attendance_day_status_full_short,
        AttendanceDayStatus.late => l10n.attendance_day_status_late_short,
        AttendanceDayStatus.partial => l10n.attendance_day_status_partial_short,
        AttendanceDayStatus.absent => l10n.attendance_day_status_absent,
        AttendanceDayStatus.excused => l10n.attendance_day_status_excused,
        AttendanceDayStatus.off => l10n.attendance_day_status_off,
      };
}

extension AttendanceAbsenceKindL10n on AttendanceAbsenceKind {
  String label(AppLocalizations l10n) => switch (this) {
        AttendanceAbsenceKind.dayOff => l10n.attendance_absence_kind_day_off,
        AttendanceAbsenceKind.vacation => l10n.attendance_absence_kind_vacation,
        AttendanceAbsenceKind.sick => l10n.attendance_absence_kind_sick,
      };
}

extension AttendanceOvertimeStatusL10n on AttendanceOvertimeStatus {
  String label(AppLocalizations l10n) => switch (this) {
        AttendanceOvertimeStatus.pending => l10n.attendance_overtime_status_pending,
        AttendanceOvertimeStatus.approved => l10n.attendance_overtime_status_approved,
        AttendanceOvertimeStatus.rejected => l10n.attendance_overtime_status_rejected,
      };
}

extension AttendanceCorrectionStatusL10n on AttendanceCorrectionStatus {
  String label(AppLocalizations l10n) => switch (this) {
        AttendanceCorrectionStatus.pending => l10n.attendance_correction_status_pending,
        AttendanceCorrectionStatus.approved => l10n.attendance_correction_status_approved,
        AttendanceCorrectionStatus.rejected => l10n.attendance_correction_status_rejected,
      };
}

extension AttendanceWorkerInviteStatusL10n on AttendanceWorkerInviteStatus {
  String label(AppLocalizations l10n) => switch (this) {
        AttendanceWorkerInviteStatus.accepted => l10n.attendance_worker_status_accepted,
        AttendanceWorkerInviteStatus.pending => l10n.attendance_worker_status_pending,
        AttendanceWorkerInviteStatus.archived => l10n.attendance_worker_status_archived,
        AttendanceWorkerInviteStatus.declined => l10n.attendance_worker_status_declined,
      };
}
