import 'package:clover/feature/_booking_/my_bookings/data/models/my_booking_item.dart';
import 'package:clover/feature/_booking_/my_bookings/data/repository/my_bookings_repository.dart';
import 'package:clover/feature/_booking_/shared/data/models/booking_status.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

@injectable
class MyBookingDetailCubit extends Cubit<MyBookingDetailState> {
  MyBookingDetailCubit(this._repository, @factoryParam MyBookingItem item)
      : super(MyBookingDetailState(item: item));

  final MyBookingsRepository _repository;

  Future<void> cancel() async {
    if (state.isBusy) return;
    emit(state.copyWith(isBusy: true));
    try {
      await _repository.cancelBooking(state.item.id);
      emit(state.copyWith(isBusy: false));
    } catch (_) {
      emit(state.copyWith(isBusy: false));
      rethrow;
    }
  }

  Future<void> reschedule({
    required String staffId,
    required DateTime startsAt,
  }) async {
    if (state.isBusy) return;
    emit(state.copyWith(isBusy: true));
    try {
      await _repository.rescheduleBooking(
        bookingId: state.item.id,
        staffId: staffId,
        startsAt: startsAt,
      );
      emit(
        state.copyWith(
          item: state.item.copyWith(
            startsAt: startsAt.toUtc().toIso8601String(),
            status: BookingStatus.confirmed,
          ),
          isBusy: false,
        ),
      );
    } catch (_) {
      emit(state.copyWith(isBusy: false));
      rethrow;
    }
  }
}

class MyBookingDetailState {
  const MyBookingDetailState({
    required this.item,
    this.isBusy = false,
  });

  final MyBookingItem item;
  final bool isBusy;

  MyBookingDetailState copyWith({
    MyBookingItem? item,
    bool? isBusy,
  }) {
    return MyBookingDetailState(
      item: item ?? this.item,
      isBusy: isBusy ?? this.isBusy,
    );
  }
}
