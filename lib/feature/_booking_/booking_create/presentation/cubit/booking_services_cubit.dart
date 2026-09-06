import 'package:clover/core/session/app_session.dart';
import 'package:clover/feature/_booking_/booking_create/data/models/booking_service.dart';
import 'package:clover/feature/_booking_/booking_create/data/models/booking_service_executor.dart';
import 'package:clover/feature/_booking_/booking_create/data/repository/booking_services_repository.dart';
import 'package:clover/feature/_booking_/booking_create/data/repository/booking_staff_repository.dart';
import 'package:clover/feature/_booking_/shared/data/booking_local_cache.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

part 'booking_services_cubit.freezed.dart';

@injectable
class BookingServicesCubit extends Cubit<BookingServicesState> {
  BookingServicesCubit(
    this._servicesRepository,
    this._staffRepository,
    this._cache,
    this._session,
  ) : super(const BookingServicesState.initial());

  final BookingServicesRepository _servicesRepository;
  final BookingStaffRepository _staffRepository;
  final BookingLocalCache _cache;
  final AppSession _session;

  Future<void> load() async {
    if (isClosed) return;

    final uid = _session.userId;
    if (uid != null && uid.isNotEmpty) {
      final cachedServices = await _cache.readMyServices(uid);
      final cachedStaff = await _cache.readMyStaff(uid);
      if (isClosed) return;
      if (cachedServices != null && cachedServices.isNotEmpty) {
        emit(
          BookingServicesState.loaded(
            services: cachedServices,
            staff: cachedStaff ?? const [],
            isFromCache: true,
          ),
        );
      } else {
        emit(const BookingServicesState.loading());
      }
    } else {
      emit(const BookingServicesState.loading());
    }

    await _syncRemote();
  }

  Future<void> refresh() async {
    if (isClosed) return;
    final loaded = state.mapOrNull(loaded: (s) => s);
    if (loaded != null) {
      emit(loaded.copyWith(isRefreshing: true));
    } else {
      emit(const BookingServicesState.loading());
    }
    await _syncRemote();
  }

  Future<void> _syncRemote() async {
    try {
      final results = await Future.wait([
        _servicesRepository.listMyServices(),
        _staffRepository.listMyStaff(),
      ]);
      if (isClosed) return;

      final services = results[0] as List<BookingService>;
      final staff = results[1] as List<BookingServiceExecutor>;

      emit(
        BookingServicesState.loaded(
          services: services,
          staff: staff,
          isFromCache: false,
          isRefreshing: false,
        ),
      );

      final uid = _session.userId;
      if (uid != null && uid.isNotEmpty) {
        await Future.wait([
          _cache.writeMyServices(uid, services),
          _cache.writeMyStaff(uid, staff),
        ]);
      }
    } catch (e) {
      if (isClosed) return;
      final loaded = state.mapOrNull(loaded: (s) => s);
      if (loaded != null) {
        emit(loaded.copyWith(isRefreshing: false));
        return;
      }
      emit(BookingServicesState.error('$e'));
    }
  }
}

@freezed
class BookingServicesState with _$BookingServicesState {
  const factory BookingServicesState.initial() = _Initial;
  const factory BookingServicesState.loading() = _Loading;
  const factory BookingServicesState.loaded({
    required List<BookingService> services,
    required List<BookingServiceExecutor> staff,
    @Default(false) bool isFromCache,
    @Default(false) bool isRefreshing,
  }) = _Loaded;
  const factory BookingServicesState.error(String message) = _Error;
}
