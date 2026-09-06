import 'package:clover/feature/_attendance_/attendance_analytics/data/attendance_analytics_loader.dart';
import 'package:clover/feature/_attendance_/attendance_analytics/data/models/attendance_analytics_models.dart';
import 'package:clover/feature/_attendance_/shared/data/attendance_context_store.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_workplace.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

@injectable
class AttendanceCompanyCubit extends Cubit<AttendanceCompanyState> {
  AttendanceCompanyCubit(this._store, this._loader) : super(const AttendanceCompanyState.initial()) {
    _store.snapshot.addListener(_onSnapshot);
  }

  final AttendanceContextStore _store;
  final AttendanceAnalyticsLoader _loader;
  String? _workplaceId;

  @override
  Future<void> close() {
    _store.snapshot.removeListener(_onSnapshot);
    return super.close();
  }

  void _onSnapshot() {
    final id = _workplaceId;
    if (id == null || isClosed) return;
    final snap = _store.snapshot.value;
    final workplace = snap?.workplaceById(id);
    if (snap == null || workplace == null) {
      emit(const AttendanceCompanyState.missing());
      return;
    }
    final prev = state;
    if (prev is AttendanceCompanyLoaded) {
      emit(prev.copyWith(workplace: workplace));
    }
  }

  Future<void> load(String workplaceId) async {
    _workplaceId = workplaceId;
    final snap = _store.snapshot.value;
    final workplace = snap?.workplaceById(workplaceId);
    if (snap == null || workplace == null) {
      emit(const AttendanceCompanyState.missing());
      return;
    }

    emit(AttendanceCompanyState.loading(workplace: workplace));
    final today = DateTime.now();
    final day = DateTime(today.year, today.month, today.day);
    final overview = await _loader.loadOverview(
      workplaceId: workplaceId,
      start: day,
      end: day,
    );
    if (isClosed) return;
    emit(
      AttendanceCompanyState.loaded(
        workplace: workplace,
        todayOverview: overview,
      ),
    );
  }
}

sealed class AttendanceCompanyState {
  const AttendanceCompanyState();

  const factory AttendanceCompanyState.initial() = AttendanceCompanyInitial;
  const factory AttendanceCompanyState.missing() = AttendanceCompanyMissing;
  const factory AttendanceCompanyState.loading({required AttendanceWorkplace workplace}) =
      AttendanceCompanyLoading;
  const factory AttendanceCompanyState.loaded({
    required AttendanceWorkplace workplace,
    required AttendanceAnalyticsOverview todayOverview,
  }) = AttendanceCompanyLoaded;
}

final class AttendanceCompanyInitial extends AttendanceCompanyState {
  const AttendanceCompanyInitial();
}

final class AttendanceCompanyMissing extends AttendanceCompanyState {
  const AttendanceCompanyMissing();
}

final class AttendanceCompanyLoading extends AttendanceCompanyState {
  const AttendanceCompanyLoading({required this.workplace});
  final AttendanceWorkplace workplace;
}

final class AttendanceCompanyLoaded extends AttendanceCompanyState {
  const AttendanceCompanyLoaded({
    required this.workplace,
    required this.todayOverview,
  });

  final AttendanceWorkplace workplace;
  final AttendanceAnalyticsOverview todayOverview;

  AttendanceCompanyLoaded copyWith({AttendanceWorkplace? workplace}) {
    return AttendanceCompanyLoaded(
      workplace: workplace ?? this.workplace,
      todayOverview: todayOverview,
    );
  }
}
