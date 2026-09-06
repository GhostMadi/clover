import 'package:clover/feature/_attendance_/attendance_analytics/data/attendance_analytics_loader.dart';
import 'package:clover/feature/_attendance_/attendance_analytics/data/models/attendance_analytics_models.dart';
import 'package:clover/feature/_attendance_/shared/data/attendance_context_store.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

@injectable
class AttendanceAnalyticsCubit extends Cubit<AttendanceAnalyticsState> {
  AttendanceAnalyticsCubit(this._store, this._loader) : super(const AttendanceAnalyticsState.initial());

  final AttendanceContextStore _store;
  final AttendanceAnalyticsLoader _loader;

  Future<void> load({
    required String workplaceId,
    required DateTime start,
    required DateTime end,
  }) async {
    if (_store.snapshot.value == null) {
      emit(const AttendanceAnalyticsState.missing());
      return;
    }

    emit(
      AttendanceAnalyticsState.loading(
        workplaceId: workplaceId,
        start: start,
        end: end,
      ),
    );

    final overview = await _loader.loadOverview(
      workplaceId: workplaceId,
      start: start,
      end: end,
    );
    if (isClosed) return;
    emit(
      AttendanceAnalyticsState.loaded(
        workplaceId: workplaceId,
        start: start,
        end: end,
        overview: overview,
        fromRemotePeriod: _store.isRemote,
      ),
    );
  }
}

sealed class AttendanceAnalyticsState {
  const AttendanceAnalyticsState();

  const factory AttendanceAnalyticsState.initial() = AttendanceAnalyticsInitial;
  const factory AttendanceAnalyticsState.missing() = AttendanceAnalyticsMissing;
  const factory AttendanceAnalyticsState.loading({
    required String workplaceId,
    required DateTime start,
    required DateTime end,
  }) = AttendanceAnalyticsLoading;
  const factory AttendanceAnalyticsState.loaded({
    required String workplaceId,
    required DateTime start,
    required DateTime end,
    required AttendanceAnalyticsOverview overview,
    required bool fromRemotePeriod,
  }) = AttendanceAnalyticsLoaded;
}

final class AttendanceAnalyticsInitial extends AttendanceAnalyticsState {
  const AttendanceAnalyticsInitial();
}

final class AttendanceAnalyticsMissing extends AttendanceAnalyticsState {
  const AttendanceAnalyticsMissing();
}

final class AttendanceAnalyticsLoading extends AttendanceAnalyticsState {
  const AttendanceAnalyticsLoading({
    required this.workplaceId,
    required this.start,
    required this.end,
  });

  final String workplaceId;
  final DateTime start;
  final DateTime end;
}

final class AttendanceAnalyticsLoaded extends AttendanceAnalyticsState {
  const AttendanceAnalyticsLoaded({
    required this.workplaceId,
    required this.start,
    required this.end,
    required this.overview,
    required this.fromRemotePeriod,
  });

  final String workplaceId;
  final DateTime start;
  final DateTime end;
  final AttendanceAnalyticsOverview overview;
  final bool fromRemotePeriod;
}
