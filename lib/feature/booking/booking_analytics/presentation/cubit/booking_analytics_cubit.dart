import 'package:clover/feature/booking/booking_analytics/data/repository/booking_analytics_repository.dart';
import 'package:clover/feature/booking/booking_create/data/models/booking_service_executor.dart';
import 'package:clover/feature/booking/booking_create/data/repository/booking_staff_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

part 'booking_analytics_cubit.freezed.dart';

@injectable
class BookingAnalyticsCubit extends Cubit<BookingAnalyticsState> {
  BookingAnalyticsCubit(this._repository, this._staffRepository)
      : super(const BookingAnalyticsState.initial());

  final BookingAnalyticsRepository _repository;
  final BookingStaffRepository _staffRepository;

  Future<void> load({
    required DateTime start,
    required DateTime end,
    String? staffId,
  }) async {
    emit(BookingAnalyticsState.loading(start: start, end: end, staffId: staffId));
    try {
      final results = await Future.wait([
        _repository.load(start: start, end: end, staffId: staffId),
        _staffRepository.listMyStaff(),
      ]);
      if (isClosed) return;
      emit(BookingAnalyticsState.loaded(
        start: start,
        end: end,
        staffId: staffId,
        result: results[0] as BookingAnalyticsResult,
        staff: results[1] as List<BookingServiceExecutor>,
      ));
    } catch (e) {
      if (isClosed) return;
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
  }) = _Loaded;
  const factory BookingAnalyticsState.error({
    required DateTime start,
    required DateTime end,
    String? staffId,
    required String message,
  }) = _Error;
}
