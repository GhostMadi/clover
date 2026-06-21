import 'package:clover/feature/booking/booking_client/data/models/client_booking_slot.dart';
import 'package:clover/feature/booking/booking_client/data/repository/booking_client_repository.dart';
import 'package:clover/feature/booking/booking_create/data/models/booking_service.dart';
import 'package:clover/feature/booking/booking_create/data/models/booking_service_executor.dart';
import 'package:clover/feature/booking/booking_create/data/repository/booking_services_repository.dart';
import 'package:clover/feature/booking/booking_settings/data/models/booking_schedule_settings.dart';
import 'package:clover/feature/booking/shared/data/models/client_booking_slot_status.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

part 'booking_client_cubit.freezed.dart';

@injectable
class BookingClientCubit extends Cubit<BookingClientState> {
  BookingClientCubit(this._repository) : super(const BookingClientState.initial());

  final BookingClientRepository _repository;

  Future<void> init({required String hostId, required String hostDisplayName}) async {
    emit(BookingClientState.loading(hostId: hostId, hostDisplayName: hostDisplayName));
    try {
      final results = await Future.wait([
        _repository.loadCatalog(hostId),
        _repository.loadHostSchedule(hostId),
      ]);
      if (isClosed) return;

      final catalog = results[0] as List<BookingServiceWithStaff>;
      final schedule = results[1] as BookingScheduleSettings;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      emit(BookingClientState.ready(
        hostId: hostId,
        hostDisplayName: hostDisplayName,
        catalog: catalog,
        schedule: schedule,
        selectedDay: today,
      ));
    } catch (e) {
      if (isClosed) return;
      emit(BookingClientState.error(hostId: hostId, hostDisplayName: hostDisplayName, message: '$e'));
    }
  }

  void selectService(BookingService service) {
    final ready = state.mapOrNull(ready: (s) => s);
    if (ready == null) return;

    final entry = ready.catalog.where((c) => c.service.id == service.id).firstOrNull;
    final executors = entry?.staff ?? const [];
    emit(ready.copyWith(
      selectedService: service,
      selectedExecutor: executors.length == 1 ? executors.first : null,
      selectedSlotStart: null,
      slots: const [],
      dayUnavailableReason: null,
      conflictMessage: null,
    ));
    if (executors.length == 1) {
      _loadAvailability();
    }
  }

  void selectExecutor(BookingServiceExecutor executor) {
    final ready = state.mapOrNull(ready: (s) => s);
    if (ready == null) return;
    emit(ready.copyWith(
      selectedExecutor: executor,
      selectedSlotStart: null,
      slots: const [],
      conflictMessage: null,
    ));
    _loadAvailability();
  }

  void selectDay(DateTime day) {
    final ready = state.mapOrNull(ready: (s) => s);
    if (ready == null) return;
    emit(ready.copyWith(
      selectedDay: DateTime(day.year, day.month, day.day),
      selectedSlotStart: null,
      conflictMessage: null,
    ));
    _loadAvailability();
  }

  void selectSlot(ClientBookingSlot slot) {
    final ready = state.mapOrNull(ready: (s) => s);
    if (ready == null) return;

    if (slot.status == ClientBookingSlotStatus.myConflict) {
      emit(ready.copyWith(
        conflictMessage: slot.conflictLabel ?? 'Это время пересекается с вашей другой записью',
      ));
      return;
    }
    if (slot.status == ClientBookingSlotStatus.hostBusy) {
      final name = ready.selectedExecutor?.displayName ?? ready.hostDisplayName;
      emit(ready.copyWith(conflictMessage: 'Это время уже занято у $name'));
      return;
    }
    if (!slot.isSelectable) return;

    final slots = [
      for (final item in ready.slots)
        item.copyWith(
          status: item.startsAt == slot.startsAt
              ? ClientBookingSlotStatus.selected
              : (item.status == ClientBookingSlotStatus.selected
                  ? ClientBookingSlotStatus.available
                  : item.status),
        ),
    ];

    emit(ready.copyWith(
      selectedSlotStart: slot.startsAt,
      slots: slots,
      conflictMessage: null,
    ));
  }

  Future<bool> confirm({String? clientComment}) async {
    final ready = state.mapOrNull(ready: (s) => s);
    if (ready == null ||
        ready.selectedService == null ||
        ready.selectedExecutor == null ||
        ready.selectedSlotStart == null ||
        ready.isSubmitting) {
      return false;
    }

    emit(ready.copyWith(isSubmitting: true));
    try {
      await _repository.createBooking(
        hostId: ready.hostId,
        serviceId: ready.selectedService!.id,
        staffId: ready.selectedExecutor!.id,
        startsAt: ready.selectedSlotStart!,
        clientNotes: clientComment,
      );
      if (isClosed) return false;
      emit(ready.copyWith(isSubmitting: false));
      return true;
    } catch (e) {
      if (isClosed) return false;
      emit(ready.copyWith(isSubmitting: false, conflictMessage: '$e'));
      return false;
    }
  }

  Future<void> _loadAvailability() async {
    final ready = state.mapOrNull(ready: (s) => s);
    if (ready == null) return;

    final service = ready.selectedService;
    final executor = ready.selectedExecutor;
    if (service == null || executor == null) return;

    emit(ready.copyWith(isLoadingSlots: true));
    try {
      final result = await _repository.loadAvailability(
        hostId: ready.hostId,
        serviceId: service.id,
        staffId: executor.id,
        day: ready.selectedDay,
      );
      if (isClosed) return;

      final selected = ready.selectedSlotStart;
      final slots = [
        for (final slot in result.slots)
          slot.copyWith(
            status: selected != null && _sameMinute(slot.startsAt, selected)
                ? ClientBookingSlotStatus.selected
                : slot.status,
          ),
      ];

      emit(ready.copyWith(
        slots: slots,
        dayUnavailableReason: result.dayUnavailableReason,
        isLoadingSlots: false,
      ));
    } catch (e) {
      if (isClosed) return;
      emit(ready.copyWith(isLoadingSlots: false, conflictMessage: '$e'));
    }
  }

  bool _sameMinute(DateTime a, DateTime b) {
    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day &&
        a.hour == b.hour &&
        a.minute == b.minute;
  }
}

extension _CatalogFirst<E> on Iterable<E> {
  E? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    return iterator.current;
  }
}

@freezed
abstract class BookingClientState with _$BookingClientState {
  const factory BookingClientState.initial() = _Initial;

  const factory BookingClientState.loading({
    required String hostId,
    required String hostDisplayName,
  }) = _Loading;

  const factory BookingClientState.ready({
    required String hostId,
    required String hostDisplayName,
    required List<BookingServiceWithStaff> catalog,
    required BookingScheduleSettings schedule,
    required DateTime selectedDay,
    BookingService? selectedService,
    BookingServiceExecutor? selectedExecutor,
    DateTime? selectedSlotStart,
    @Default([]) List<ClientBookingSlot> slots,
    String? dayUnavailableReason,
    String? conflictMessage,
    @Default(false) bool isLoadingSlots,
    @Default(false) bool isSubmitting,
  }) = _Ready;

  const factory BookingClientState.error({
    required String hostId,
    required String hostDisplayName,
    required String message,
  }) = _Error;
}
