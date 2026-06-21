import 'package:clover/feature/booking/booking_list/data/models/booking_list_date_range.dart';
import 'package:clover/feature/booking/my_bookings/data/models/my_booking_item.dart';
import 'package:clover/feature/booking/my_bookings/data/repository/my_bookings_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

part 'my_bookings_cubit.freezed.dart';

@injectable
class MyBookingsCubit extends Cubit<MyBookingsState> {
  MyBookingsCubit(this._repository) : super(const MyBookingsState.initial());

  final MyBookingsRepository _repository;

  Future<void> load({BookingListDateRange? period}) async {
    final range = period ?? BookingListDateRange.recentAndUpcoming();
    emit(MyBookingsState.loading(period: range));
    try {
      final items = await _repository.listBookings(
        from: range.start,
        to: range.end.add(const Duration(days: 1)).subtract(const Duration(seconds: 1)),
      );
      if (isClosed) return;
      items.sort((a, b) {
        final ad = a.startsAtDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bd = b.startsAtDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        return ad.compareTo(bd);
      });
      emit(MyBookingsState.loaded(period: range, items: items));
    } catch (e) {
      if (isClosed) return;
      emit(MyBookingsState.error(period: range, message: '$e'));
    }
  }

  Future<void> setPeriod(BookingListDateRange period) => load(period: period);

  Future<void> refresh() async {
    final period = state.mapOrNull(
      loaded: (s) => s.period,
      loading: (s) => s.period,
      error: (s) => s.period,
    );
    if (period == null) {
      await load();
      return;
    }
    await load(period: period);
  }
}

@freezed
class MyBookingsState with _$MyBookingsState {
  const factory MyBookingsState.initial() = _Initial;
  const factory MyBookingsState.loading({required BookingListDateRange period}) = _Loading;
  const factory MyBookingsState.loaded({
    required BookingListDateRange period,
    required List<MyBookingItem> items,
  }) = _Loaded;
  const factory MyBookingsState.error({
    required BookingListDateRange period,
    required String message,
  }) = _Error;
}
