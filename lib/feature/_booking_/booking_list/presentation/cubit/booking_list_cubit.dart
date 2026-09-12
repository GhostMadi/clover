import 'package:clover/core/session/app_session.dart';
import 'package:clover/feature/_booking_/booking_create/data/repository/booking_services_repository.dart';
import 'package:clover/feature/_booking_/booking_list/data/booking_host_inbox.dart';
import 'package:clover/feature/_booking_/booking_list/data/models/booking_list_date_range.dart';
import 'package:clover/feature/_booking_/booking_list/data/models/booking_list_item.dart';
import 'package:clover/feature/_booking_/booking_list/data/repository/booking_host_list_repository.dart';
import 'package:clover/feature/_booking_/shared/data/booking_local_cache.dart';
import 'package:clover/feature/_booking_/shared/data/models/booking_status.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

@injectable
class BookingListCubit extends Cubit<BookingListState> {
  BookingListCubit(this._repository, this._services, this._cache, this._session)
      : super(const BookingListState.initial());

  final BookingHostListRepository _repository;
  final BookingServicesRepository _services;
  final BookingLocalCache _cache;
  final AppSession _session;

  String? _lastQuery;
  String? _pointId;
  Set<String> _serviceIds = {};
  final Set<String> _updatingIds = {};

  Future<void> load({BookingListDateRange? period, String? query, String? pointId}) async {
    if (isClosed) return;
    final range = period ?? BookingListDateRange.hostInbox();
    _lastQuery = query;
    if (pointId != null) {
      _pointId = pointId.trim().isEmpty ? null : pointId.trim();
    }

    final previous = state.mapOrNull(loaded: (s) => s);
    final tab = previous?.mainTabIndex ?? BookingHostInboxTab.upcoming.index;
    final day = previous?.upcomingDay;

    final uid = _session.userId;
    if (uid != null && uid.isNotEmpty) {
      final cached = await _cache.readHostBookings(
        uid,
        range,
        query: query,
        pointId: _pointId,
      );
      if (isClosed) return;
      if (cached != null && cached.isNotEmpty) {
        emit(
          BookingListState.loaded(
            period: range,
            query: query,
            items: cached,
            mainTabIndex: tab,
            upcomingDay: day,
            isFromCache: true,
          ),
        );
      } else {
        emit(BookingListState.loading(period: range, query: query));
      }
    } else {
      emit(BookingListState.loading(period: range, query: query));
    }

    await _syncRemote(range, query: query, mainTabIndex: tab, upcomingDay: day);
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
        ) ??
        BookingListDateRange.hostInbox();
    await load(period: period, query: query);
  }

  void setMainTab(int index) {
    final loaded = state.mapOrNull(loaded: (s) => s);
    if (loaded == null) return;
    emit(loaded.copyWith(mainTabIndex: index.clamp(0, BookingHostInboxTab.values.length - 1)));
  }

  void setUpcomingDay(DateTime day) {
    final loaded = state.mapOrNull(loaded: (s) => s);
    if (loaded == null) return;
    emit(loaded.copyWith(upcomingDay: BookingHostInbox.dayKey(day)));
  }

  Future<void> refresh() async {
    if (isClosed) return;
    final period = state.mapOrNull(
      loaded: (s) => s.period,
      loading: (s) => s.period,
      error: (s) => s.period,
    );
    if (period == null) {
      await load(query: _lastQuery);
      return;
    }

    final loaded = state.mapOrNull(loaded: (s) => s);
    if (loaded != null) {
      emit(loaded.copyWith(isRefreshing: true));
    }
    await _syncRemote(
      period,
      query: _lastQuery,
      mainTabIndex: loaded?.mainTabIndex ?? BookingHostInboxTab.upcoming.index,
      upcomingDay: loaded?.upcomingDay,
    );
  }

  void patchItem(BookingListItem updated) {
    if (isClosed) return;
    final loaded = state.mapOrNull(loaded: (s) => s);
    if (loaded == null) return;

    final index = loaded.items.indexWhere((item) => item.id == updated.id);
    if (index < 0) return;

    final items = List<BookingListItem>.from(loaded.items)..[index] = updated;
    emit(loaded.copyWith(items: items, isFromCache: false));
  }

  bool isUpdating(String bookingId) => _updatingIds.contains(bookingId);

  Future<bool> updateStatus(String bookingId, BookingStatus status) async {
    final id = bookingId.trim();
    if (id.isEmpty || _updatingIds.contains(id)) return false;

    _updatingIds.add(id);
    _emitUpdating();

    try {
      await _repository.updateBookingStatus(id, status);
      if (isClosed) return false;

      final loaded = state.mapOrNull(loaded: (s) => s);
      if (loaded != null) {
        final index = loaded.items.indexWhere((item) => item.id == id);
        if (index >= 0) {
          final items = List<BookingListItem>.from(loaded.items);
          items[index] = items[index].copyWith(status: status);
          emit(loaded.copyWith(items: items, isFromCache: false));
        }
      }
      return true;
    } catch (_) {
      return false;
    } finally {
      _updatingIds.remove(id);
      if (!isClosed) _emitUpdating();
    }
  }

  void _emitUpdating() {
    final loaded = state.mapOrNull(loaded: (s) => s);
    if (loaded == null) return;
    emit(loaded.copyWith(updatingIds: {..._updatingIds}));
  }

  Future<void> _syncRemote(
    BookingListDateRange range, {
    String? query,
    required int mainTabIndex,
    DateTime? upcomingDay,
  }) async {
    try {
      final pid = _pointId;
      if (pid != null && pid.isNotEmpty) {
        final services = await _services.listMyServices(pointId: pid);
        _serviceIds = {
          for (final s in services)
            if (s.id.trim().isNotEmpty) s.id.trim(),
        };
      } else {
        _serviceIds = {};
      }

      final raw = await _repository.listBookings(
        from: range.start,
        to: range.end.add(const Duration(days: 1)).subtract(const Duration(seconds: 1)),
        query: query,
        limit: 100,
      );
      if (isClosed) return;

      final items = _serviceIds.isEmpty
          ? raw
          : [
              for (final item in raw)
                if (item.serviceId != null && _serviceIds.contains(item.serviceId)) item,
            ];

      final day = upcomingDay ?? BookingHostInbox.dayKey(DateTime.now());

      emit(
        BookingListState.loaded(
          period: range,
          query: query,
          items: items,
          mainTabIndex: mainTabIndex,
          upcomingDay: day,
          isFromCache: false,
          isRefreshing: false,
          updatingIds: {..._updatingIds},
        ),
      );

      final uid = _session.userId;
      if (uid != null && uid.isNotEmpty) {
        await _cache.writeHostBookings(uid, range, items, query: query, pointId: _pointId);
      }
    } catch (e) {
      if (isClosed) return;
      final loaded = state.mapOrNull(loaded: (s) => s);
      if (loaded != null) {
        emit(loaded.copyWith(isRefreshing: false));
        return;
      }
      emit(BookingListState.error(period: range, query: query, message: '$e'));
    }
  }
}

sealed class BookingListState {
  const BookingListState();

  const factory BookingListState.initial() = BookingListInitial;
  const factory BookingListState.loading({
    required BookingListDateRange period,
    String? query,
  }) = BookingListLoading;
  const factory BookingListState.loaded({
    required BookingListDateRange period,
    String? query,
    required List<BookingListItem> items,
    int mainTabIndex,
    DateTime? upcomingDay,
    bool isFromCache,
    bool isRefreshing,
    Set<String> updatingIds,
  }) = BookingListLoaded;
  const factory BookingListState.error({
    required BookingListDateRange period,
    String? query,
    required String message,
  }) = BookingListError;

  T? mapOrNull<T>({
    T Function(BookingListLoaded s)? loaded,
    T Function(BookingListLoading s)? loading,
    T Function(BookingListError s)? error,
  }) {
    final self = this;
    if (self is BookingListLoaded && loaded != null) return loaded(self);
    if (self is BookingListLoading && loading != null) return loading(self);
    if (self is BookingListError && error != null) return error(self);
    return null;
  }

  T maybeMap<T>({
    required T Function() orElse,
    T Function(BookingListLoaded s)? loaded,
    T Function(BookingListLoading s)? loading,
    T Function(BookingListError s)? error,
  }) {
    final self = this;
    if (self is BookingListLoaded && loaded != null) return loaded(self);
    if (self is BookingListLoading && loading != null) return loading(self);
    if (self is BookingListError && error != null) return error(self);
    return orElse();
  }
}

final class BookingListInitial extends BookingListState {
  const BookingListInitial();
}

final class BookingListLoading extends BookingListState {
  const BookingListLoading({required this.period, this.query});

  final BookingListDateRange period;
  final String? query;
}

final class BookingListLoaded extends BookingListState {
  const BookingListLoaded({
    required this.period,
    this.query,
    required this.items,
    this.mainTabIndex = 1,
    this.upcomingDay,
    this.isFromCache = false,
    this.isRefreshing = false,
    this.updatingIds = const {},
  });

  final BookingListDateRange period;
  final String? query;
  final List<BookingListItem> items;
  final int mainTabIndex;
  final DateTime? upcomingDay;
  final bool isFromCache;
  final bool isRefreshing;
  final Set<String> updatingIds;

  BookingListLoaded copyWith({
    BookingListDateRange? period,
    String? query,
    List<BookingListItem>? items,
    int? mainTabIndex,
    DateTime? upcomingDay,
    bool? isFromCache,
    bool? isRefreshing,
    Set<String>? updatingIds,
  }) {
    return BookingListLoaded(
      period: period ?? this.period,
      query: query ?? this.query,
      items: items ?? this.items,
      mainTabIndex: mainTabIndex ?? this.mainTabIndex,
      upcomingDay: upcomingDay ?? this.upcomingDay,
      isFromCache: isFromCache ?? this.isFromCache,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      updatingIds: updatingIds ?? this.updatingIds,
    );
  }
}

final class BookingListError extends BookingListState {
  const BookingListError({
    required this.period,
    this.query,
    required this.message,
  });

  final BookingListDateRange period;
  final String? query;
  final String message;
}
