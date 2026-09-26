import 'package:clover/feature/_booking_/booking_client/data/models/client_booking_slot.dart';
import 'package:clover/feature/_booking_/booking_client/data/repository/booking_client_repository.dart';
import 'package:clover/feature/_booking_/booking_create/data/models/booking_service.dart';
import 'package:clover/feature/_booking_/booking_create/data/models/booking_service_executor.dart';
import 'package:clover/feature/_booking_/booking_create/data/repository/booking_services_repository.dart';
import 'package:clover/feature/_booking_/booking_settings/data/models/booking_schedule_settings.dart';
import 'package:clover/feature/_booking_/shared/data/models/client_booking_slot_status.dart';
import 'package:clover/feature/_booking_/space_plan_bind/data/booking_space_plan_bind_mock.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/locale/app_locale_cubit.dart';
import 'package:clover/l10n/app_localizations.dart';

part 'booking_client_cubit.freezed.dart';

@injectable
class BookingClientCubit extends Cubit<BookingClientState> {
  BookingClientCubit(this._repository) : super(const BookingClientState.initial());

  final BookingClientRepository _repository;

  Future<void> init({
    required String hostId,
    required String hostDisplayName,
    String? initialServiceId,
  }) async {
    emit(BookingClientState.loading(hostId: hostId, hostDisplayName: hostDisplayName));
    try {
      final results = await Future.wait([
        _repository.loadCatalog(hostId),
        _repository.loadHostSchedule(hostId),
        _repository.getMyBonusBalanceAtHost(hostId),
      ]);
      if (isClosed) return;

      var catalog = results[0] as List<BookingServiceWithStaff>;
      var schedule = results[1] as BookingScheduleSettings;
      final bonusBalance = results[2] as int;

      // Гостевой mock-схема: каталог с мастерами + горизонт дат, слоты локально.
      if (BookingSpacePlanBindMock.enabled) {
        catalog = BookingSpacePlanBindMock.enrichCatalogForGuest(catalog);
        schedule = BookingSpacePlanBindMock.demoGuestSchedule();
      }

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      BookingService? selectedService;
      BookingServiceExecutor? selectedExecutor;
      final presetId = initialServiceId?.trim();
      if (presetId != null && presetId.isNotEmpty) {
        final entry = catalog.where((c) => c.service.id == presetId).firstOrNull;
        if (entry != null && entry.service.isActive) {
          selectedService = entry.service;
          final executors = entry.staff;
          if (executors.length == 1) {
            selectedExecutor = executors.first;
          }
        }
      }

      emit(BookingClientState.ready(
        hostId: hostId,
        hostDisplayName: hostDisplayName,
        catalog: catalog,
        schedule: schedule,
        selectedDay: today,
        bonusBalanceAtHost: bonusBalance,
        selectedService: selectedService,
        selectedExecutor: selectedExecutor,
      ));

      if (selectedExecutor != null) {
        await _loadAvailability();
      }
    } catch (e) {
      if (isClosed) return;
      // Mock: даже при ошибке API — демо-каталог, чтобы дата/слоты работали.
      if (BookingSpacePlanBindMock.enabled) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        emit(BookingClientState.ready(
          hostId: hostId,
          hostDisplayName: hostDisplayName,
          catalog: BookingSpacePlanBindMock.demoGuestCatalog(),
          schedule: BookingSpacePlanBindMock.demoGuestSchedule(),
          selectedDay: today,
          bonusBalanceAtHost: 0,
        ));
        return;
      }
      emit(BookingClientState.error(hostId: hostId, hostDisplayName: hostDisplayName, message: '$e'));
    }
  }

  /// Место со схемы → услуга + мастер + сразу слоты на выбранный день.
  void applyPlaceSelection({
    required BookingService service,
    required BookingServiceExecutor executor,
  }) {
    final ready = state.mapOrNull(ready: (s) => s);
    if (ready == null) return;
    emit(ready.copyWith(
      selectedService: service,
      selectedExecutor: executor,
      selectedSlotStart: null,
      slots: const [],
      dayUnavailableReason: null,
      conflictMessage: null,
      useBonuses: true,
    ));
    _loadAvailability();
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
      useBonuses: true,
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
        conflictMessage: slot.conflictLabel ?? lookupAppLocalizations(sl<AppLocaleCubit>().state.locale).booking_slot_conflict_self,
      ));
      return;
    }
    if (slot.status == ClientBookingSlotStatus.hostBusy) {
      final name = ready.selectedExecutor?.displayName ?? ready.hostDisplayName;
      emit(ready.copyWith(conflictMessage: lookupAppLocalizations(sl<AppLocaleCubit>().state.locale).booking_slot_taken_by(name)));
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

  void setUseBonuses(bool value) {
    final ready = state.mapOrNull(ready: (s) => s);
    if (ready == null) return;
    emit(ready.copyWith(useBonuses: value));
  }

  Future<void> _loadAvailability() async {
    final ready = state.mapOrNull(ready: (s) => s);
    if (ready == null) return;

    final service = ready.selectedService;
    final executor = ready.selectedExecutor;
    if (service == null || executor == null) return;

    // Mock-схема: слоты всегда локально — дата/время выбираются без бэка.
    if (BookingSpacePlanBindMock.enabled) {
      var day = ready.selectedDay;
      var slots = _demoSlotsForDay(day);
      // Если на сегодня уже поздно — сдвигаем на ближайший день со слотами.
      if (slots.isEmpty) {
        for (var i = 1; i <= 14 && slots.isEmpty; i++) {
          day = DateTime(ready.selectedDay.year, ready.selectedDay.month, ready.selectedDay.day)
              .add(Duration(days: i));
          slots = _demoSlotsForDay(day);
        }
      }

      DateTime? selected = ready.selectedSlotStart;
      if (selected != null && !slots.any((s) => _sameMinute(s.startsAt, selected!))) {
        selected = null;
      }
      // Полный mock-флоу: сразу есть выбранное время → видна «Записаться».
      selected ??= slots.isNotEmpty ? slots.first.startsAt : null;

      final painted = [
        for (final slot in slots)
          slot.copyWith(
            status: selected != null && _sameMinute(slot.startsAt, selected)
                ? ClientBookingSlotStatus.selected
                : ClientBookingSlotStatus.available,
          ),
      ];

      emit(ready.copyWith(
        selectedDay: day,
        selectedSlotStart: selected,
        slots: painted,
        dayUnavailableReason: null,
        isLoadingSlots: false,
        conflictMessage: null,
      ));
      return;
    }

    emit(ready.copyWith(isLoadingSlots: true, conflictMessage: null));
    try {
      final result = await _repository.loadAvailability(
        hostId: ready.hostId,
        serviceId: service.id,
        staffId: executor.id,
        day: ready.selectedDay,
      );
      if (isClosed) return;

      final selected = ready.selectedSlotStart;
      final painted = [
        for (final slot in result.slots)
          slot.copyWith(
            status: selected != null && _sameMinute(slot.startsAt, selected)
                ? ClientBookingSlotStatus.selected
                : slot.status,
          ),
      ];

      emit(ready.copyWith(
        slots: painted,
        dayUnavailableReason: result.dayUnavailableReason,
        isLoadingSlots: false,
      ));
    } catch (e) {
      if (isClosed) return;
      emit(ready.copyWith(isLoadingSlots: false, conflictMessage: '$e'));
    }
  }

  /// Демо-слоты 10:00–19:30, шаг 30 мин (только для mock-схемы).
  List<ClientBookingSlot> _demoSlotsForDay(DateTime day) {
    final now = DateTime.now();
    final out = <ClientBookingSlot>[];
    for (var h = 10; h <= 19; h++) {
      for (final m in const [0, 30]) {
        if (h == 19 && m == 30) continue;
        final t = DateTime(day.year, day.month, day.day, h, m);
        if (t.isBefore(now.add(const Duration(minutes: 15)))) continue;
        out.add(
          ClientBookingSlot(
            startsAt: t,
            status: ClientBookingSlotStatus.available,
          ),
        );
      }
    }
    return out;
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
        useBonuses: ready.useBonuses,
      );
      if (isClosed) return false;
      emit(ready.copyWith(isSubmitting: false));
      return true;
    } catch (e) {
      if (isClosed) return false;
      // Mock-схема: не блокируем демо, если бэк отклонил слот.
      if (BookingSpacePlanBindMock.enabled) {
        emit(ready.copyWith(isSubmitting: false, conflictMessage: null));
        return true;
      }
      emit(ready.copyWith(isSubmitting: false, conflictMessage: '$e'));
      return false;
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
    @Default(true) bool useBonuses,
    @Default(0) int bonusBalanceAtHost,
  }) = _Ready;

  const factory BookingClientState.error({
    required String hostId,
    required String hostDisplayName,
    required String message,
  }) = _Error;
}
