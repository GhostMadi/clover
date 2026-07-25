import 'package:clover/feature/_booking_/booking_list/data/models/booking_list_date_range.dart';
import 'package:clover/feature/_booking_/my_bookings/data/models/my_booking_item.dart';
import 'package:clover/feature/_booking_/my_bookings/data/repository/my_bookings_repository.dart';
import 'package:clover/feature/_booking_/shared/data/booking_local_cache.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'my_bookings_cubit.freezed.dart';

@injectable
class MyBookingsCubit extends Cubit<MyBookingsState> {
  MyBookingsCubit(this._repository, this._cache, this._client) : super(const MyBookingsState.initial());

  final MyBookingsRepository _repository;
  final BookingLocalCache _cache;
  final SupabaseClient _client;

  Future<void> load({BookingListDateRange? period}) async {
    if (isClosed) return;
    final range = period ?? BookingListDateRange.recentAndUpcoming();

    final uid = _client.auth.currentUser?.id.trim();
    if (uid != null && uid.isNotEmpty) {
      final cached = await _cache.readMyBookings(uid, range);
      if (isClosed) return;
      if (cached != null && cached.isNotEmpty) {
        emit(
          MyBookingsState.loaded(
            period: range,
            items: _sorted(cached),
            isFromCache: true,
          ),
        );
      } else {
        emit(MyBookingsState.loading(period: range));
      }
    } else {
      emit(MyBookingsState.loading(period: range));
    }

    await _syncRemote(range);
  }

  Future<void> setPeriod(BookingListDateRange period) => load(period: period);

  Future<void> refresh() async {
    if (isClosed) return;
    final period = state.mapOrNull(
      loaded: (s) => s.period,
      loading: (s) => s.period,
      error: (s) => s.period,
    );
    if (period == null) {
      await load();
      return;
    }

    final cur = state;
    final loaded = cur.mapOrNull(loaded: (s) => s);
    if (loaded != null) {
      emit(loaded.copyWith(isRefreshing: true));
    }
    await _syncRemote(period);
  }

  Future<void> _syncRemote(BookingListDateRange range) async {
    try {
      final items = await _repository.listBookings(
        from: range.start,
        to: range.end.add(const Duration(days: 1)).subtract(const Duration(seconds: 1)),
      );
      if (isClosed) return;

      final sorted = _sorted(items);
      emit(
        MyBookingsState.loaded(
          period: range,
          items: sorted,
          isFromCache: false,
          isRefreshing: false,
        ),
      );

      final uid = _client.auth.currentUser?.id.trim();
      if (uid != null && uid.isNotEmpty) {
        await _cache.writeMyBookings(uid, range, sorted);
      }
    } catch (e) {
      if (isClosed) return;
      final loaded = state.mapOrNull(loaded: (s) => s);
      if (loaded != null) {
        emit(loaded.copyWith(isRefreshing: false));
        return;
      }
      emit(MyBookingsState.error(period: range, message: '$e'));
    }
  }

  List<MyBookingItem> _sorted(List<MyBookingItem> items) {
    final copy = List<MyBookingItem>.from(items);
    copy.sort((a, b) {
      final ad = a.startsAtDate ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bd = b.startsAtDate ?? DateTime.fromMillisecondsSinceEpoch(0);
      return ad.compareTo(bd);
    });
    return List.unmodifiable(copy);
  }
}

@freezed
class MyBookingsState with _$MyBookingsState {
  const factory MyBookingsState.initial() = _Initial;
  const factory MyBookingsState.loading({required BookingListDateRange period}) = _Loading;
  const factory MyBookingsState.loaded({
    required BookingListDateRange period,
    required List<MyBookingItem> items,
    @Default(false) bool isFromCache,
    @Default(false) bool isRefreshing,
  }) = _Loaded;
  const factory MyBookingsState.error({
    required BookingListDateRange period,
    required String message,
  }) = _Error;
}
