import 'package:clover/core/session/app_session.dart';
import 'package:clover/feature/_booking_/booking_create/data/models/booking_service.dart';
import 'package:clover/feature/_booking_/booking_create/data/models/booking_service_executor.dart';
import 'package:clover/feature/_booking_/booking_create/data/repository/booking_services_repository.dart';
import 'package:clover/feature/_booking_/booking_create/data/repository/booking_staff_repository.dart';
import 'package:clover/feature/_booking_/shared/data/booking_local_cache.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

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

  String? _pointId;

  Future<void> load({String? pointId}) async {
    if (isClosed) return;
    _pointId = pointId?.trim();
    if (_pointId != null && _pointId!.isEmpty) _pointId = null;

    final uid = _session.userId;
    if (uid != null && uid.isNotEmpty) {
      final cachedServices = await _cache.readMyServices(uid, pointId: _pointId);
      final cachedStaff = await _cache.readMyStaff(uid);
      if (isClosed) return;
      if (cachedServices != null && cachedServices.isNotEmpty) {
        emit(
          BookingServicesState.loaded(
            services: cachedServices,
            staff: cachedStaff ?? const [],
            isFromCache: true,
            pointId: _pointId,
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
    final loaded = state is BookingServicesLoaded ? state as BookingServicesLoaded : null;
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
        _servicesRepository.listMyServices(pointId: _pointId),
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
          pointId: _pointId,
        ),
      );

      final uid = _session.userId;
      if (uid != null && uid.isNotEmpty) {
        await Future.wait([
          _cache.writeMyServices(uid, services, pointId: _pointId),
          _cache.writeMyStaff(uid, staff),
        ]);
      }
    } catch (e) {
      if (isClosed) return;
      final loaded = state is BookingServicesLoaded ? state as BookingServicesLoaded : null;
      if (loaded != null) {
        emit(loaded.copyWith(isRefreshing: false));
        return;
      }
      emit(BookingServicesState.error('$e'));
    }
  }
}

sealed class BookingServicesState {
  const BookingServicesState();

  const factory BookingServicesState.initial() = BookingServicesInitial;
  const factory BookingServicesState.loading() = BookingServicesLoading;
  const factory BookingServicesState.loaded({
    required List<BookingService> services,
    required List<BookingServiceExecutor> staff,
    bool isFromCache,
    bool isRefreshing,
    String? pointId,
  }) = BookingServicesLoaded;
  const factory BookingServicesState.error(String message) = BookingServicesError;

  T maybeMap<T>({
    required T Function() orElse,
    T Function(BookingServicesLoaded s)? loaded,
    T Function(BookingServicesError s)? error,
    T Function(BookingServicesLoading s)? loading,
  }) {
    final self = this;
    if (self is BookingServicesLoaded && loaded != null) return loaded(self);
    if (self is BookingServicesError && error != null) return error(self);
    if (self is BookingServicesLoading && loading != null) return loading(self);
    return orElse();
  }
}

final class BookingServicesInitial extends BookingServicesState {
  const BookingServicesInitial();
}

final class BookingServicesLoading extends BookingServicesState {
  const BookingServicesLoading();
}

final class BookingServicesLoaded extends BookingServicesState {
  const BookingServicesLoaded({
    required this.services,
    required this.staff,
    this.isFromCache = false,
    this.isRefreshing = false,
    this.pointId,
  });

  final List<BookingService> services;
  final List<BookingServiceExecutor> staff;
  final bool isFromCache;
  final bool isRefreshing;
  final String? pointId;

  BookingServicesLoaded copyWith({
    List<BookingService>? services,
    List<BookingServiceExecutor>? staff,
    bool? isFromCache,
    bool? isRefreshing,
    String? pointId,
  }) {
    return BookingServicesLoaded(
      services: services ?? this.services,
      staff: staff ?? this.staff,
      isFromCache: isFromCache ?? this.isFromCache,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      pointId: pointId ?? this.pointId,
    );
  }
}

final class BookingServicesError extends BookingServicesState {
  const BookingServicesError(this.message);

  final String message;
}
