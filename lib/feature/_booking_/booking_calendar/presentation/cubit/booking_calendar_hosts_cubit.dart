import 'package:clover/core/session/app_session.dart';
import 'package:clover/feature/_booking_/booking_calendar/data/models/booking_calendar_host.dart';
import 'package:clover/feature/_booking_/booking_calendar/data/repository/booking_calendar_repository.dart';
import 'package:clover/feature/_booking_/shared/data/booking_error.dart';
import 'package:clover/feature/_booking_/shared/data/booking_local_cache.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

part 'booking_calendar_hosts_cubit.freezed.dart';

@injectable
class BookingCalendarHostsCubit extends Cubit<BookingCalendarHostsState> {
  BookingCalendarHostsCubit(this._repository, this._cache, this._session)
      : super(const BookingCalendarHostsState.initial());

  final BookingCalendarRepository _repository;
  final BookingLocalCache _cache;
  final AppSession _session;

  Future<void> load() async {
    if (isClosed) return;
    final uid = _session.userId;
    if (uid != null && uid.isNotEmpty) {
      final cached = await _cache.readCalendarHosts(uid);
      if (isClosed) return;
      if (cached != null && cached.isNotEmpty) {
        emit(BookingCalendarHostsState.loaded(hosts: cached, isFromCache: true));
      } else {
        emit(const BookingCalendarHostsState.loading());
      }
    } else {
      emit(const BookingCalendarHostsState.loading());
    }
    await _syncRemote();
  }

  Future<void> refresh() => load();

  Future<void> _syncRemote() async {
    try {
      final hosts = await _repository.listHosts();
      if (isClosed) return;
      emit(BookingCalendarHostsState.loaded(hosts: hosts));
      final uid = _session.userId;
      if (uid != null && uid.isNotEmpty) {
        await _cache.writeCalendarHosts(uid, hosts);
      }
    } catch (e) {
      if (isClosed) return;
      final loaded = state.mapOrNull(loaded: (s) => s);
      if (loaded != null) {
        emit(loaded.copyWith(isFromCache: true));
        return;
      }
      emit(BookingCalendarHostsState.error(message: BookingException.from(e).message ?? 'Не удалось загрузить'));
    }
  }
}

@freezed
class BookingCalendarHostsState with _$BookingCalendarHostsState {
  const factory BookingCalendarHostsState.initial() = _Initial;
  const factory BookingCalendarHostsState.loading() = _Loading;
  const factory BookingCalendarHostsState.loaded({
    required List<BookingCalendarHost> hosts,
    @Default(false) bool isFromCache,
  }) = _Loaded;
  const factory BookingCalendarHostsState.error({required String message}) = _Error;
}
