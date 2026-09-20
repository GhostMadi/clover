import 'package:clover/core/session/app_session.dart';
import 'package:clover/feature/_attendance_/shared/data/attendance_context_store.dart';
import 'package:clover/feature/_attendance_/shared/data/attendance_local_cache.dart';
import 'package:clover/feature/_attendance_/shared/data/attendance_workplaces_prefs.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_workplace.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

@injectable
class AttendanceCompanyCubit extends Cubit<AttendanceCompanyState> {
  AttendanceCompanyCubit(
    this._store,
    this._cache,
    this._prefs,
    this._session,
  ) : super(const AttendanceCompanyState.initial()) {
    _store.snapshot.addListener(_onSnapshot);
  }

  final AttendanceContextStore _store;
  final AttendanceLocalCache _cache;
  final AttendanceWorkplacesPrefs _prefs;
  final AppSession _session;
  String? _workplaceId;

  @override
  Future<void> close() {
    _store.snapshot.removeListener(_onSnapshot);
    return super.close();
  }

  void _onSnapshot() {
    final id = _workplaceId;
    if (id == null || isClosed) return;
    final workplace = _store.snapshot.value?.workplaceById(id);
    if (workplace == null) return;
    final prev = state;
    if (prev is AttendanceCompanyLoaded) {
      emit(prev.copyWith(workplace: workplace));
    } else if (prev is AttendanceCompanyLoading || prev is AttendanceCompanyMissing) {
      emit(AttendanceCompanyState.loaded(workplace: workplace));
    }
  }

  Future<void> load(String workplaceId) async {
    _workplaceId = workplaceId;
    await _prefs.writeLastWorkplaceId(workplaceId);

    final fromStore = _store.snapshot.value?.workplaceById(workplaceId);
    if (fromStore != null) {
      if (!isClosed) emit(AttendanceCompanyState.loaded(workplace: fromStore));
      return;
    }

    final uid = _session.userId;
    if (uid != null && uid.isNotEmpty) {
      final cached = await _cache.readWorkplace(uid, workplaceId);
      if (!isClosed && cached != null) {
        emit(AttendanceCompanyState.loaded(workplace: cached, isFromCache: true));
      } else if (!isClosed) {
        emit(const AttendanceCompanyState.loading());
      }
    } else if (!isClosed) {
      emit(const AttendanceCompanyState.loading());
    }

    try {
      await _store.hydrateCurrent(force: _store.snapshot.value == null);
    } catch (_) {
      // leave cache paint if any
    }
    if (isClosed) return;

    final workplace = _store.snapshot.value?.workplaceById(workplaceId);
    if (workplace == null) {
      if (state is! AttendanceCompanyLoaded) {
        emit(const AttendanceCompanyState.missing());
      }
      return;
    }
    emit(AttendanceCompanyState.loaded(workplace: workplace));
  }
}

sealed class AttendanceCompanyState {
  const AttendanceCompanyState();

  const factory AttendanceCompanyState.initial() = AttendanceCompanyInitial;
  const factory AttendanceCompanyState.missing() = AttendanceCompanyMissing;
  const factory AttendanceCompanyState.loading() = AttendanceCompanyLoading;
  const factory AttendanceCompanyState.loaded({
    required AttendanceWorkplace workplace,
    bool isFromCache,
  }) = AttendanceCompanyLoaded;
}

final class AttendanceCompanyInitial extends AttendanceCompanyState {
  const AttendanceCompanyInitial();
}

final class AttendanceCompanyMissing extends AttendanceCompanyState {
  const AttendanceCompanyMissing();
}

final class AttendanceCompanyLoading extends AttendanceCompanyState {
  const AttendanceCompanyLoading();
}

final class AttendanceCompanyLoaded extends AttendanceCompanyState {
  const AttendanceCompanyLoaded({
    required this.workplace,
    this.isFromCache = false,
  });

  final AttendanceWorkplace workplace;
  final bool isFromCache;

  AttendanceCompanyLoaded copyWith({AttendanceWorkplace? workplace, bool? isFromCache}) {
    return AttendanceCompanyLoaded(
      workplace: workplace ?? this.workplace,
      isFromCache: isFromCache ?? this.isFromCache,
    );
  }
}
