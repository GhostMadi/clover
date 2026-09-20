import 'package:clover/core/session/app_session.dart';
import 'package:clover/feature/_booking_/booking_create/data/models/booking_service_executor.dart';
import 'package:clover/feature/_booking_/booking_create/data/models/booking_staff_invite.dart';
import 'package:clover/feature/_booking_/booking_create/data/repository/booking_staff_repository.dart';
import 'package:clover/feature/_booking_/shared/data/booking_local_cache.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

@injectable
class BookingTeamCubit extends Cubit<BookingTeamState> {
  BookingTeamCubit(
    this._staffRepository,
    this._cache,
    this._session,
  ) : super(const BookingTeamState.initial());

  final BookingStaffRepository _staffRepository;
  final BookingLocalCache _cache;
  final AppSession _session;

  Future<void> load() async {
    final uid = _session.userId;
    if (uid != null && uid.isNotEmpty) {
      final cachedStaff = await _cache.readMyStaff(uid);
      if (!isClosed && cachedStaff != null) {
        emit(
          BookingTeamState.loaded(
            staff: cachedStaff,
            pending: state.maybeMap(loaded: (s) => s.pending, orElse: () => const []),
            isRefreshing: true,
          ),
        );
      } else if (!isClosed) {
        emit(const BookingTeamState.loading());
      }
    } else if (!isClosed) {
      emit(const BookingTeamState.loading());
    }

    await refresh();
  }

  Future<void> refresh() async {
    final uid = _session.userId;
    try {
      final results = await Future.wait([
        _staffRepository.listMyStaff(),
        _staffRepository.listPendingInvites(),
      ]);
      final staff = results[0] as List<BookingServiceExecutor>;
      final pending = results[1] as List<BookingStaffInvite>;
      if (uid != null && uid.isNotEmpty) {
        await _cache.writeMyStaff(uid, staff);
      }
      if (isClosed) return;
      emit(BookingTeamState.loaded(staff: staff, pending: pending));
    } catch (e) {
      if (isClosed) return;
      final keep = state.maybeMap(loaded: (s) => s, orElse: () => null);
      if (keep != null) {
        emit(keep.copyWith(isRefreshing: false));
      } else {
        emit(BookingTeamState.error('$e'));
      }
    }
  }

  Future<void> removeStaff(String staffId) async {
    final loaded = state.maybeMap(loaded: (s) => s, orElse: () => null);
    if (loaded == null) return;

    final id = staffId.trim();
    if (id.isEmpty) return;

    final prev = loaded.staff;
    BookingServiceExecutor? target;
    for (final s in prev) {
      if (s.id == id) {
        target = s;
        break;
      }
    }
    if (target == null) return;

    final next = [for (final s in prev) if (s.id != id) s];
    emit(loaded.copyWith(staff: next));

    try {
      await _staffRepository.updateStaff(
        id: id,
        displayName: target.displayName,
        isActive: false,
      );
      final uid = _session.userId;
      if (uid != null && uid.isNotEmpty) {
        await _cache.writeMyStaff(uid, next);
      }
    } catch (e) {
      if (isClosed) return;
      emit(loaded.copyWith(staff: prev));
      rethrow;
    }
  }

  Future<void> cancelInvite(String inviteId) async {
    await _staffRepository.cancelInvite(inviteId);
    await refresh();
  }
}

sealed class BookingTeamState {
  const BookingTeamState();

  const factory BookingTeamState.initial() = BookingTeamInitial;
  const factory BookingTeamState.loading() = BookingTeamLoading;
  const factory BookingTeamState.loaded({
    required List<BookingServiceExecutor> staff,
    required List<BookingStaffInvite> pending,
    bool isRefreshing,
  }) = BookingTeamLoaded;
  const factory BookingTeamState.error(String message) = BookingTeamError;

  T maybeMap<T>({
    required T Function() orElse,
    T Function(BookingTeamLoaded s)? loaded,
    T Function(BookingTeamError s)? error,
    T Function(BookingTeamLoading s)? loading,
  }) {
    final self = this;
    if (self is BookingTeamLoaded && loaded != null) return loaded(self);
    if (self is BookingTeamError && error != null) return error(self);
    if (self is BookingTeamLoading && loading != null) return loading(self);
    return orElse();
  }
}

final class BookingTeamInitial extends BookingTeamState {
  const BookingTeamInitial();
}

final class BookingTeamLoading extends BookingTeamState {
  const BookingTeamLoading();
}

final class BookingTeamLoaded extends BookingTeamState {
  const BookingTeamLoaded({
    required this.staff,
    required this.pending,
    this.isRefreshing = false,
  });

  final List<BookingServiceExecutor> staff;
  final List<BookingStaffInvite> pending;
  final bool isRefreshing;

  BookingTeamLoaded copyWith({
    List<BookingServiceExecutor>? staff,
    List<BookingStaffInvite>? pending,
    bool? isRefreshing,
  }) {
    return BookingTeamLoaded(
      staff: staff ?? this.staff,
      pending: pending ?? this.pending,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }
}

final class BookingTeamError extends BookingTeamState {
  const BookingTeamError(this.message);
  final String message;
}
