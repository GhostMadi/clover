import 'package:clover/core/session/app_session.dart';
import 'package:clover/feature/_booking_/booking_calendar/data/models/booking_calendar_item.dart';
import 'package:clover/feature/_booking_/booking_calendar/data/repository/booking_calendar_repository.dart';
import 'package:clover/feature/_booking_/booking_list/data/models/booking_list_date_range.dart';
import 'package:clover/feature/_booking_/shared/data/booking_error.dart';
import 'package:clover/feature/_booking_/shared/data/booking_local_cache.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/locale/app_locale_cubit.dart';
import 'package:clover/l10n/app_localizations.dart';

part 'booking_calendar_bookings_cubit.freezed.dart';

@injectable
class BookingCalendarBookingsCubit extends Cubit<BookingCalendarBookingsState> {
  BookingCalendarBookingsCubit(this._repository, this._cache, this._session)
      : super(const BookingCalendarBookingsState.initial());

  final BookingCalendarRepository _repository;
  final BookingLocalCache _cache;
  final AppSession _session;

  Future<void> load({required String hostId, BookingListDateRange? period}) async {
    if (isClosed) return;
    final range = period ?? BookingListDateRange.recentAndUpcoming();
    final uid = _session.userId;
    if (uid != null && uid.isNotEmpty) {
      final cached = await _cache.readCalendarItems(uid, hostId, range);
      if (isClosed) return;
      if (cached != null && cached.isNotEmpty) {
        emit(
          BookingCalendarBookingsState.loaded(
            period: range,
            hostId: hostId,
            items: _sorted(cached),
            isFromCache: true,
          ),
        );
      } else {
        emit(BookingCalendarBookingsState.loading(period: range, hostId: hostId));
      }
    } else {
      emit(BookingCalendarBookingsState.loading(period: range, hostId: hostId));
    }
    await _sync(hostId, range);
  }

  Future<void> refresh() async {
    if (isClosed) return;
    final hostId = state.mapOrNull(
      loaded: (s) => s.hostId,
      loading: (s) => s.hostId,
      error: (s) => s.hostId,
    );
    final period = state.mapOrNull(
      loaded: (s) => s.period,
      loading: (s) => s.period,
      error: (s) => s.period,
    );
    if (hostId == null || period == null) return;
    final loaded = state.mapOrNull(loaded: (s) => s);
    if (loaded != null) {
      emit(loaded.copyWith(isRefreshing: true));
    }
    await _sync(hostId, period);
  }

  Future<void> _sync(String hostId, BookingListDateRange range) async {
    try {
      final items = await _repository.listBookings(
        from: range.start,
        to: range.end.add(const Duration(days: 1)).subtract(const Duration(seconds: 1)),
        hostId: hostId,
      );
      if (isClosed) return;
      final sorted = _sorted(items);
      emit(
        BookingCalendarBookingsState.loaded(
          period: range,
          hostId: hostId,
          items: sorted,
        ),
      );
      final uid = _session.userId;
      if (uid != null && uid.isNotEmpty) {
        await _cache.writeCalendarItems(uid, hostId, range, sorted);
      }
    } catch (e) {
      if (isClosed) return;
      final loaded = state.mapOrNull(loaded: (s) => s);
      if (loaded != null) {
        emit(loaded.copyWith(isRefreshing: false));
        return;
      }
      emit(
        BookingCalendarBookingsState.error(
          period: range,
          hostId: hostId,
          message: BookingException.from(e).message ?? lookupAppLocalizations(sl<AppLocaleCubit>().state.locale).booking_load_failed,
        ),
      );
    }
  }

  List<BookingCalendarItem> _sorted(List<BookingCalendarItem> items) {
    return [...items]..sort((a, b) {
          final ad = a.startsAtDate ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bd = b.startsAtDate ?? DateTime.fromMillisecondsSinceEpoch(0);
          return ad.compareTo(bd);
        });
  }
}

@freezed
class BookingCalendarBookingsState with _$BookingCalendarBookingsState {
  const factory BookingCalendarBookingsState.initial() = _Initial;
  const factory BookingCalendarBookingsState.loading({
    required BookingListDateRange period,
    required String hostId,
  }) = _Loading;
  const factory BookingCalendarBookingsState.loaded({
    required BookingListDateRange period,
    required String hostId,
    required List<BookingCalendarItem> items,
    @Default(false) bool isRefreshing,
    @Default(false) bool isFromCache,
  }) = _Loaded;
  const factory BookingCalendarBookingsState.error({
    required BookingListDateRange period,
    required String hostId,
    required String message,
  }) = _Error;
}
