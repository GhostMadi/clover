import 'package:clover/feature/_booking_/booking_client/data/models/client_booking_slot.dart';
import 'package:clover/feature/_booking_/booking_client/data/repository/booking_client_repository.dart';
import 'package:clover/feature/_booking_/shared/data/booking_error.dart';
import 'package:clover/feature/_booking_/shared/data/models/client_booking_slot_status.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

@injectable
class BookingRescheduleCubit extends Cubit<BookingRescheduleState> {
  BookingRescheduleCubit(this._repository)
    : super(
        BookingRescheduleState(
          day: _dateOnly(DateTime.now()),
          slots: const [],
          loading: false,
        ),
      );

  final BookingClientRepository _repository;

  String? _hostId;
  String? _serviceId;
  String? _staffId;
  String? _bookingId;
  int _requestId = 0;

  Future<void> load({
    required String hostId,
    required String serviceId,
    required String staffId,
    required String bookingId,
    DateTime? initialDay,
  }) async {
    _hostId = hostId;
    _serviceId = serviceId;
    _staffId = staffId;
    _bookingId = bookingId;

    final today = _dateOnly(DateTime.now());
    final requestedDay = _dateOnly(initialDay ?? today);
    final day = requestedDay.isBefore(today) ? today : requestedDay;
    emit(BookingRescheduleState(day: day, slots: const [], loading: true));
    await _loadAvailability(day);
  }

  void selectDay(DateTime day) {
    final selectedDay = _dateOnly(day);
    emit(
      BookingRescheduleState(day: selectedDay, slots: const [], loading: true),
    );
    _loadAvailability(selectedDay);
  }

  void selectSlot(DateTime startsAt) {
    final available = state.slots.any(
      (slot) =>
          slot.status == ClientBookingSlotStatus.available &&
          _sameMinute(slot.startsAt, startsAt),
    );
    if (!available) return;

    emit(
      BookingRescheduleState(
        day: state.day,
        slots: state.slots,
        loading: false,
        dayUnavailableReason: state.dayUnavailableReason,
        selectedStartsAt: startsAt,
      ),
    );
  }

  Future<void> _loadAvailability(DateTime day) async {
    final hostId = _hostId;
    final serviceId = _serviceId;
    final staffId = _staffId;
    final bookingId = _bookingId;
    if (hostId == null ||
        serviceId == null ||
        staffId == null ||
        bookingId == null) {
      return;
    }

    final requestId = ++_requestId;
    try {
      final result = await _repository.loadAvailability(
        hostId: hostId,
        serviceId: serviceId,
        staffId: staffId,
        day: day,
        excludeBookingId: bookingId,
      );
      if (isClosed || requestId != _requestId) return;

      final slots = result.slots
          .where((slot) => slot.status == ClientBookingSlotStatus.available)
          .toList(growable: false);
      emit(
        BookingRescheduleState(
          day: day,
          slots: slots,
          loading: false,
          dayUnavailableReason: result.dayUnavailableReason,
        ),
      );
    } catch (error) {
      if (isClosed || requestId != _requestId) return;
      emit(
        BookingRescheduleState(
          day: day,
          slots: const [],
          loading: false,
          dayUnavailableReason: BookingException.from(error).userMessage,
        ),
      );
    }
  }

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static bool _sameMinute(DateTime a, DateTime b) =>
      a.year == b.year &&
      a.month == b.month &&
      a.day == b.day &&
      a.hour == b.hour &&
      a.minute == b.minute;
}

class BookingRescheduleState {
  const BookingRescheduleState({
    required this.day,
    required this.slots,
    required this.loading,
    this.dayUnavailableReason,
    this.selectedStartsAt,
  });

  final DateTime day;
  final List<ClientBookingSlot> slots;
  final bool loading;
  final String? dayUnavailableReason;
  final DateTime? selectedStartsAt;
}
