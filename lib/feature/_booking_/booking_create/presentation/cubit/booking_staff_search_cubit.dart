import 'package:clover/feature/_booking_/booking_create/data/models/booking_service_executor.dart';
import 'package:clover/feature/_booking_/booking_create/data/models/booking_staff_invite.dart';
import 'package:clover/feature/_booking_/booking_create/data/models/booking_staff_profile.dart';
import 'package:clover/feature/_booking_/booking_create/data/repository/booking_staff_repository.dart';
import 'package:clover/feature/_booking_/shared/data/booking_error.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

/// Шторка исполнителей: команда + поиск + invite + имя.
@injectable
class BookingStaffSearchCubit extends Cubit<BookingStaffSearchState> {
  BookingStaffSearchCubit(this._repository) : super(const BookingStaffSearchState());

  final BookingStaffRepository _repository;
  Set<String> _excludeProfileIds = const {};

  void configure({Set<String> excludeProfileIds = const {}}) {
    _excludeProfileIds = excludeProfileIds;
  }

  Future<void> loadTeam() async {
    emit(state.copyWith(loadingTeam: true, clearError: true));
    try {
      final results = await Future.wait([
        _repository.listMyStaff(),
        _repository.listPendingInvites(),
      ]);
      if (isClosed) return;
      emit(
        state.copyWith(
          staff: results[0] as List<BookingServiceExecutor>,
          pending: results[1] as List<BookingStaffInvite>,
          loadingTeam: false,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          loadingTeam: false,
          error: BookingException.from(e).userMessage,
        ),
      );
    }
  }

  Future<void> search(String query) async {
    emit(state.copyWith(loadingSearch: true, clearSearchError: true));
    try {
      final rows = await _repository.searchProfiles(
        query,
        excludeProfileIds: _excludeProfileIds,
      );
      if (isClosed) return;
      emit(state.copyWith(results: rows, loadingSearch: false));
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          loadingSearch: false,
          searchError: BookingException.from(e).userMessage,
          results: const [],
        ),
      );
    }
  }

  Future<void> invite(String profileId) async {
    if (state.busy) return;
    emit(state.copyWith(busy: true));
    try {
      await _repository.inviteStaff(profileId);
      if (isClosed) return;
      await loadTeam();
      if (isClosed) return;
      emit(state.copyWith(busy: false, lastAction: BookingStaffSheetAction.invited));
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          busy: false,
          lastAction: BookingStaffSheetAction.failed,
          actionError: BookingException.from(e).userMessage,
        ),
      );
    }
  }

  Future<void> cancelInvite(String inviteId) async {
    if (state.busy) return;
    emit(state.copyWith(busy: true));
    try {
      await _repository.cancelInvite(inviteId);
      if (isClosed) return;
      await loadTeam();
      if (isClosed) return;
      emit(state.copyWith(busy: false, lastAction: BookingStaffSheetAction.inviteCancelled));
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          busy: false,
          lastAction: BookingStaffSheetAction.failed,
          actionError: BookingException.from(e).userMessage,
        ),
      );
    }
  }

  Future<BookingServiceExecutor?> createNameOnly(String displayName) async {
    final name = displayName.trim();
    if (name.isEmpty || state.busy) return null;
    emit(state.copyWith(busy: true));
    try {
      final staff = await _repository.createStaff(displayName: name);
      if (isClosed) return null;
      emit(state.copyWith(busy: false, lastAction: BookingStaffSheetAction.created));
      return staff;
    } catch (e) {
      if (isClosed) return null;
      emit(
        state.copyWith(
          busy: false,
          lastAction: BookingStaffSheetAction.failed,
          actionError: BookingException.from(e).userMessage,
        ),
      );
      return null;
    }
  }

  void clearLastAction() {
    if (state.lastAction == null && state.actionError == null) return;
    emit(state.copyWith(clearLastAction: true));
  }
}

enum BookingStaffSheetAction { invited, inviteCancelled, created, failed }

class BookingStaffSearchState {
  const BookingStaffSearchState({
    this.staff = const [],
    this.pending = const [],
    this.results = const [],
    this.loadingTeam = false,
    this.loadingSearch = false,
    this.busy = false,
    this.error,
    this.searchError,
    this.lastAction,
    this.actionError,
  });

  final List<BookingServiceExecutor> staff;
  final List<BookingStaffInvite> pending;
  final List<BookingStaffProfile> results;
  final bool loadingTeam;
  final bool loadingSearch;
  final bool busy;
  final String? error;
  final String? searchError;
  final BookingStaffSheetAction? lastAction;
  final String? actionError;

  /// Совместимость со старым UI поиска.
  bool get loading => loadingSearch;

  BookingStaffSearchState copyWith({
    List<BookingServiceExecutor>? staff,
    List<BookingStaffInvite>? pending,
    List<BookingStaffProfile>? results,
    bool? loadingTeam,
    bool? loadingSearch,
    bool? busy,
    String? error,
    String? searchError,
    BookingStaffSheetAction? lastAction,
    String? actionError,
    bool clearError = false,
    bool clearSearchError = false,
    bool clearLastAction = false,
  }) {
    return BookingStaffSearchState(
      staff: staff ?? this.staff,
      pending: pending ?? this.pending,
      results: results ?? this.results,
      loadingTeam: loadingTeam ?? this.loadingTeam,
      loadingSearch: loadingSearch ?? this.loadingSearch,
      busy: busy ?? this.busy,
      error: clearError ? null : (error ?? this.error),
      searchError: clearSearchError ? null : (searchError ?? this.searchError),
      lastAction: clearLastAction ? null : (lastAction ?? this.lastAction),
      actionError: clearLastAction ? null : (actionError ?? this.actionError),
    );
  }
}
