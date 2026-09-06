import 'package:clover/feature/_attendance_/attendance_analytics/data/attendance_analytics.dart';
import 'package:clover/feature/_attendance_/attendance_analytics/data/attendance_analytics_loader.dart';
import 'package:clover/feature/_attendance_/attendance_analytics/data/models/attendance_analytics_models.dart';
import 'package:clover/feature/_attendance_/shared/data/attendance_context_store.dart';
import 'package:clover/feature/_attendance_/shared/data/attendance_remote_repository.dart';
import 'package:clover/feature/_attendance_/shared/data/attendance_timesheet_export.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:share_plus/share_plus.dart';

@injectable
class AttendanceTimesheetCubit extends Cubit<AttendanceTimesheetState> {
  AttendanceTimesheetCubit(this._store, this._remote, this._loader)
      : super(const AttendanceTimesheetState.initial());

  final AttendanceContextStore _store;
  final AttendanceRemoteRepository _remote;
  final AttendanceAnalyticsLoader _loader;

  Future<void> load(String workplaceId) async {
    final now = AttendanceAnalytics.today;
    final start = DateTime(now.year, now.month, 1);
    final end = now;
    emit(AttendanceTimesheetState.loading(workplaceId: workplaceId, start: start, end: end));
    final overview = await _loader.loadOverview(
      workplaceId: workplaceId,
      start: start,
      end: end,
    );
    if (isClosed) return;
    if (_store.snapshot.value == null) {
      emit(const AttendanceTimesheetState.missing());
      return;
    }
    emit(
      AttendanceTimesheetState.loaded(
        workplaceId: workplaceId,
        start: start,
        end: end,
        overview: overview,
      ),
    );
  }

  Future<bool> exportCsv() async {
    final loaded = state;
    if (loaded is! AttendanceTimesheetLoaded) return false;
    final snap = _store.snapshot.value;
    if (snap == null) return false;
    final file = await AttendanceTimesheetExport.exportCsv(
      snapshot: snap,
      workplaceId: loaded.workplaceId,
      start: loaded.start,
      end: loaded.end,
      store: _store,
      remote: _remote,
    );
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'text/csv')],
        subject: 'Табель посещаемости',
      ),
    );
    return true;
  }
}

sealed class AttendanceTimesheetState {
  const AttendanceTimesheetState();

  const factory AttendanceTimesheetState.initial() = AttendanceTimesheetInitial;
  const factory AttendanceTimesheetState.missing() = AttendanceTimesheetMissing;
  const factory AttendanceTimesheetState.loading({
    required String workplaceId,
    required DateTime start,
    required DateTime end,
  }) = AttendanceTimesheetLoading;
  const factory AttendanceTimesheetState.loaded({
    required String workplaceId,
    required DateTime start,
    required DateTime end,
    required AttendanceAnalyticsOverview overview,
  }) = AttendanceTimesheetLoaded;
}

final class AttendanceTimesheetInitial extends AttendanceTimesheetState {
  const AttendanceTimesheetInitial();
}

final class AttendanceTimesheetMissing extends AttendanceTimesheetState {
  const AttendanceTimesheetMissing();
}

final class AttendanceTimesheetLoading extends AttendanceTimesheetState {
  const AttendanceTimesheetLoading({
    required this.workplaceId,
    required this.start,
    required this.end,
  });

  final String workplaceId;
  final DateTime start;
  final DateTime end;
}

final class AttendanceTimesheetLoaded extends AttendanceTimesheetState {
  const AttendanceTimesheetLoaded({
    required this.workplaceId,
    required this.start,
    required this.end,
    required this.overview,
  });

  final String workplaceId;
  final DateTime start;
  final DateTime end;
  final AttendanceAnalyticsOverview overview;
}
