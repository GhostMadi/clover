import 'dart:io';

import 'package:clover/feature/_attendance_/attendance_analytics/data/attendance_analytics.dart';
import 'package:clover/feature/_attendance_/attendance_analytics/data/models/attendance_analytics_models.dart';
import 'package:clover/feature/_attendance_/shared/data/attendance_context_store.dart';
import 'package:clover/feature/_attendance_/shared/data/attendance_remote_repository.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_absence.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_snapshot.dart';
import 'package:path_provider/path_provider.dart';

/// Экспорт табеля в CSV (сервер при remote, иначе локально из snapshot).
abstract final class AttendanceTimesheetExport {
  static Future<File> exportCsv({
    required AttendanceSnapshot snapshot,
    required String workplaceId,
    required DateTime start,
    required DateTime end,
    AttendanceContextStore? store,
    AttendanceRemoteRepository? remote,
  }) async {
    final useRemote = store?.isRemote == true && remote != null;
    if (useRemote) {
      try {
        final csv = await remote.timesheetCsv(
          workplaceId: workplaceId,
          start: start,
          end: end,
        );
        if (csv.isNotEmpty) {
          final dir = await getTemporaryDirectory();
          final file = File('${dir.path}/tabl_${workplaceId}_${_fmt(start)}.csv');
          await file.writeAsString(csv);
          return file;
        }
      } catch (_) {
        // fallback local
      }
    }

    final workplace = snapshot.workplaceById(workplaceId);
    final name = workplace?.name ?? workplaceId;
    final rows = <List<String>>[
      ['Компания', name],
      ['Период', '${_fmt(start)} — ${_fmt(end)}'],
      [],
      ['Работник', 'Ник', 'Дата', 'Статус', 'Часы', 'Опоздание', 'Примечание'],
    ];

    final overview = AttendanceAnalytics.overview(
      snapshot: snapshot,
      workplaceId: workplaceId,
      start: start,
      end: end,
    );

    for (final worker in overview.workers) {
      for (final entry in worker.daysByKey.entries) {
        final day = entry.key;
        final record = entry.value;
        final absence = snapshot.absences.where(
          (a) => a.workplaceId == workplaceId && a.workerId == worker.id && a.covers(day),
        );
        final note = absence.isEmpty ? '' : absence.first.kind.labelRu;
        rows.add([
          worker.displayName,
          worker.username,
          _fmt(day),
          record.status.labelRu,
          record.totalLabel,
          record.status == AttendanceDayStatus.late ? 'да' : '',
          note,
        ]);
      }
    }

    final buffer = StringBuffer('\uFEFF');
    for (final row in rows) {
      buffer.writeln(row.map(_escape).join(';'));
    }

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/tabl_${workplaceId}_${_fmt(start)}.csv');
    await file.writeAsString(buffer.toString());
    return file;
  }

  static String _fmt(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '$dd.$mm.${d.year}';
  }

  static String _escape(String value) {
    if (value.contains(';') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}
