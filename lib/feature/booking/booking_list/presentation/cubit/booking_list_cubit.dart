import 'package:clover/feature/booking/booking_list/data/models/booking_list_date_range.dart';
import 'package:clover/feature/booking/booking_list/data/models/booking_list_item.dart';
import 'package:clover/feature/booking/booking_list/data/repository/booking_host_list_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

part 'booking_list_cubit.freezed.dart';

@injectable
class BookingListCubit extends Cubit<BookingListState> {
  BookingListCubit(this._repository) : super(const BookingListState.initial());

  final BookingHostListRepository _repository;

  Future<void> load({BookingListDateRange? period, String? query}) async {
    final range = period ?? BookingListDateRange.today();
    emit(BookingListState.loading(period: range, query: query));
    try {
      final items = await _repository.listBookings(
        from: range.start,
        to: range.end.add(const Duration(days: 1)).subtract(const Duration(seconds: 1)),
        query: query,
      );
      if (isClosed) return;
      emit(BookingListState.loaded(period: range, query: query, items: items));
    } catch (e) {
      if (isClosed) return;
      emit(BookingListState.error(period: range, query: query, message: '$e'));
    }
  }

  Future<void> setPeriod(BookingListDateRange period) async {
    final query = state.mapOrNull(
      loaded: (s) => s.query,
      loading: (s) => s.query,
      error: (s) => s.query,
    );
    await load(period: period, query: query);
  }

  Future<void> setQuery(String? query) async {
    final period = state.mapOrNull(
      loaded: (s) => s.period,
      loading: (s) => s.period,
      error: (s) => s.period,
    ) ?? BookingListDateRange.today();
    await load(period: period, query: query);
  }
}

@freezed
class BookingListState with _$BookingListState {
  const factory BookingListState.initial() = _Initial;
  const factory BookingListState.loading({
    required BookingListDateRange period,
    String? query,
  }) = _Loading;
  const factory BookingListState.loaded({
    required BookingListDateRange period,
    String? query,
    required List<BookingListItem> items,
  }) = _Loaded;
  const factory BookingListState.error({
    required BookingListDateRange period,
    String? query,
    required String message,
  }) = _Error;
}
