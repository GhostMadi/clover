import 'package:clover/feature/booking/booking_create/data/models/booking_service.dart';
import 'package:clover/feature/booking/booking_create/data/models/booking_service_executor.dart';
import 'package:clover/feature/booking/booking_create/data/repository/booking_services_repository.dart';
import 'package:clover/feature/booking/booking_create/data/repository/booking_staff_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

part 'booking_services_cubit.freezed.dart';

@injectable
class BookingServicesCubit extends Cubit<BookingServicesState> {
  BookingServicesCubit(this._servicesRepository, this._staffRepository)
      : super(const BookingServicesState.initial());

  final BookingServicesRepository _servicesRepository;
  final BookingStaffRepository _staffRepository;

  Future<void> load() async {
    emit(const BookingServicesState.loading());
    try {
      final results = await Future.wait([
        _servicesRepository.listMyServices(),
        _staffRepository.listMyStaff(),
      ]);
      if (isClosed) return;
      emit(BookingServicesState.loaded(
        services: results[0] as List<BookingService>,
        staff: results[1] as List<BookingServiceExecutor>,
      ));
    } catch (e) {
      if (isClosed) return;
      emit(BookingServicesState.error('$e'));
    }
  }

  Future<void> refresh() async {
    final hadData = state.mapOrNull(loaded: (_) => true) ?? false;
    if (!hadData) {
      await load();
      return;
    }
    try {
      final results = await Future.wait([
        _servicesRepository.listMyServices(),
        _staffRepository.listMyStaff(),
      ]);
      if (isClosed) return;
      emit(BookingServicesState.loaded(
        services: results[0] as List<BookingService>,
        staff: results[1] as List<BookingServiceExecutor>,
      ));
    } catch (_) {}
  }
}

@freezed
class BookingServicesState with _$BookingServicesState {
  const factory BookingServicesState.initial() = _Initial;
  const factory BookingServicesState.loading() = _Loading;
  const factory BookingServicesState.loaded({
    required List<BookingService> services,
    required List<BookingServiceExecutor> staff,
  }) = _Loaded;
  const factory BookingServicesState.error(String message) = _Error;
}
