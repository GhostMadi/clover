import 'package:clover/feature/_booking_/booking_calendar/data/models/booking_calendar_host.dart';
import 'package:clover/feature/_booking_/booking_calendar/data/repository/booking_calendar_repository.dart';
import 'package:clover/feature/_booking_/shared/data/booking_error.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

part 'booking_calendar_hosts_cubit.freezed.dart';

@injectable
class BookingCalendarHostsCubit extends Cubit<BookingCalendarHostsState> {
  BookingCalendarHostsCubit(this._repository) : super(const BookingCalendarHostsState.initial());

  final BookingCalendarRepository _repository;

  Future<void> load() async {
    if (isClosed) return;
    emit(const BookingCalendarHostsState.loading());
    try {
      final hosts = await _repository.listHosts();
      if (isClosed) return;
      emit(BookingCalendarHostsState.loaded(hosts: hosts));
    } catch (e) {
      if (isClosed) return;
      emit(BookingCalendarHostsState.error(message: BookingException.from(e).message ?? 'Не удалось загрузить'));
    }
  }

  Future<void> refresh() => load();
}

@freezed
class BookingCalendarHostsState with _$BookingCalendarHostsState {
  const factory BookingCalendarHostsState.initial() = _Initial;
  const factory BookingCalendarHostsState.loading() = _Loading;
  const factory BookingCalendarHostsState.loaded({required List<BookingCalendarHost> hosts}) = _Loaded;
  const factory BookingCalendarHostsState.error({required String message}) = _Error;
}
