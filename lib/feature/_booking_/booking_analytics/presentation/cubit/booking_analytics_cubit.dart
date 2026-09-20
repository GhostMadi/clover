import 'package:clover/core/session/app_session.dart';
import 'package:clover/feature/_booking_/booking_analytics/data/repository/booking_analytics_repository.dart';
import 'package:clover/feature/_booking_/booking_create/data/models/booking_service_executor.dart';
import 'package:clover/feature/_booking_/booking_create/data/repository/booking_staff_repository.dart';
import 'package:clover/feature/_booking_/shared/data/booking_local_cache.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

part 'booking_analytics_cubit.freezed.dart';

@injectable
class BookingAnalyticsCubit extends Cubit<BookingAnalyticsState> {
  BookingAnalyticsCubit(
    this._repository,
    this._staffRepository,
    this._cache,
    this._session,
  ) : super(const BookingAnalyticsState.initial());

  final BookingAnalyticsRepository _repository;
  final BookingStaffRepository _staffRepository;
  final BookingLocalCache _cache;
  final AppSession _session;

  Future<void> load({
    required DateTime start,
    required DateTime end,
    String? staffId,
    String? pointId,
  }) async {
    final pid = pointId?.trim() ?? '';
    final uid = _session.userId;

    if (uid != null && uid.isNotEmpty && pid.isNotEmpty) {
      final cachedResult = await _cache.readAnalytics(
        uid,
        pointId: pid,
        start: start,
        end: end,
        staffId: staffId,
      );
      final cachedStaff = await _cache.readMyStaff(uid);
      if (!isClosed && cachedResult != null) {
        emit(
          BookingAnalyticsState.loaded(
            start: start,
            end: end,
            staffId: staffId,
            result: cachedResult,
            staff: cachedStaff ?? const [],
            isFromCache: true,
          ),
        );
      } else if (!isClosed) {
        emit(BookingAnalyticsState.loading(start: start, end: end, staffId: staffId));
      }
    } else if (!isClosed) {
      emit(BookingAnalyticsState.loading(start: start, end: end, staffId: staffId));
    }

    try {
      final results = await Future.wait([
        _repository.load(start: start, end: end, staffId: staffId, pointId: pointId),
        _staffRepository.listMyStaff(),
      ]);
      if (isClosed) return;
      final result = results[0] as BookingAnalyticsResult;
      final staff = results[1] as List<BookingServiceExecutor>;
      emit(
        BookingAnalyticsState.loaded(
          start: start,
          end: end,
          staffId: staffId,
          result: result,
          staff: staff,
          isFromCache: false,
        ),
      );

      if (uid != null && uid.isNotEmpty) {
        await Future.wait([
          if (pid.isNotEmpty)
            _cache.writeAnalytics(
              uid,
              result,
              pointId: pid,
              start: start,
              end: end,
              staffId: staffId,
            ),
          _cache.writeMyStaff(uid, staff),
        ]);
      }
    } catch (e) {
      if (isClosed) return;
      final had = state.mapOrNull(loaded: (_) => true) ?? false;
      if (had) return;
      emit(BookingAnalyticsState.error(start: start, end: end, staffId: staffId, message: '$e'));
    }
  }
}

@freezed
class BookingAnalyticsState with _$BookingAnalyticsState {
  const factory BookingAnalyticsState.initial() = _Initial;
  const factory BookingAnalyticsState.loading({
    required DateTime start,
    required DateTime end,
    String? staffId,
  }) = _Loading;
  const factory BookingAnalyticsState.loaded({
    required DateTime start,
    required DateTime end,
    String? staffId,
    required BookingAnalyticsResult result,
    required List<BookingServiceExecutor> staff,
    @Default(false) bool isFromCache,
  }) = _Loaded;
  const factory BookingAnalyticsState.error({
    required DateTime start,
    required DateTime end,
    String? staffId,
    required String message,
  }) = _Error;
}
