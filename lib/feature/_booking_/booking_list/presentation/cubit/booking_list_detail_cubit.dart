import 'package:clover/feature/_booking_/booking_list/data/models/booking_list_item.dart';
import 'package:clover/feature/_booking_/booking_list/data/repository/booking_host_list_repository.dart';
import 'package:clover/feature/_booking_/shared/data/models/booking_status.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

@injectable
class BookingListDetailCubit extends Cubit<BookingListDetailState> {
  BookingListDetailCubit(this._repository, @factoryParam BookingListItem item)
      : _initialItem = item,
        super(BookingListDetailState(item: item));

  final BookingHostListRepository _repository;
  final BookingListItem _initialItem;

  bool get hasChanges =>
      state.item.status != _initialItem.status || state.item.startsAt != _initialItem.startsAt;

  Future<void> applyStatus(BookingStatus status) async {
    if (state.isUpdating) return;
    emit(state.copyWith(isUpdating: true));
    try {
      await _repository.updateBookingStatus(state.item.id, status);
      emit(state.copyWith(item: state.item.copyWith(status: status), isUpdating: false));
    } catch (_) {
      emit(state.copyWith(isUpdating: false));
      rethrow;
    }
  }

  Future<BookingStatus> revertStatus() async {
    if (state.isUpdating) throw StateError('busy');
    emit(state.copyWith(isUpdating: true));
    try {
      final status = await _repository.revertBookingStatus(state.item.id);
      emit(state.copyWith(item: state.item.copyWith(status: status), isUpdating: false));
      return status;
    } catch (_) {
      emit(state.copyWith(isUpdating: false));
      rethrow;
    }
  }

  Future<void> reschedule({
    required String staffId,
    required DateTime startsAt,
  }) async {
    if (state.isUpdating) return;
    emit(state.copyWith(isUpdating: true));
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
          isUpdating: false,
        ),
      );
    } catch (_) {
      emit(state.copyWith(isUpdating: false));
      rethrow;
    }
  }
}

class BookingListDetailState {
  const BookingListDetailState({
    required this.item,
    this.isUpdating = false,
  });

  final BookingListItem item;
  final bool isUpdating;

  BookingListDetailState copyWith({
    BookingListItem? item,
    bool? isUpdating,
  }) {
    return BookingListDetailState(
      item: item ?? this.item,
      isUpdating: isUpdating ?? this.isUpdating,
    );
  }
}
