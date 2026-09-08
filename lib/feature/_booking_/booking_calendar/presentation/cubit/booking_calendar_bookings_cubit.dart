import 'package:clover/feature/_booking_/booking_calendar/data/models/booking_calendar_item.dart';
import 'package:clover/feature/_booking_/booking_calendar/data/repository/booking_calendar_repository.dart';
import 'package:clover/feature/_booking_/booking_list/data/models/booking_list_date_range.dart';
import 'package:clover/feature/_booking_/shared/data/booking_error.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

part 'booking_calendar_bookings_cubit.freezed.dart';

@injectable
class BookingCalendarBookingsCubit extends Cubit<BookingCalendarBookingsState> {
  BookingCalendarBookingsCubit(this._repository) : super(const BookingCalendarBookingsState.initial());

  final BookingCalendarRepository _repository;

  Future<void> load({required String hostId, BookingListDateRange? period}) async {
    if (isClosed) return;
    final range = period ?? BookingListDateRange.recentAndUpcoming();
    emit(BookingCalendarBookingsState.loading(period: range, hostId: hostId));
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
      final sorted = [...items]..sort((a, b) {
        final ad = a.startsAtDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bd = b.startsAtDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        return ad.compareTo(bd);
      });
      emit(
        BookingCalendarBookingsState.loaded(
          period: range,
          hostId: hostId,
          items: sorted,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(
        BookingCalendarBookingsState.error(
          period: range,
          hostId: hostId,
          message: BookingException.from(e).message ?? 'Не удалось загрузить',
        ),
      );
    }
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
  }) = _Loaded;
  const factory BookingCalendarBookingsState.error({
    required BookingListDateRange period,
    required String hostId,
    required String message,
  }) = _Error;
}
