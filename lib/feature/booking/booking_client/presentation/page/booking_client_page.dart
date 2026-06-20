import 'package:auto_route/auto_route.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_date_picker.dart';
import 'package:clover/core/shared/app_snack_bar.dart';
import 'package:clover/feature/booking/booking_settings/data/mock/booking_schedule_settings_store.dart';
import 'package:clover/feature/booking/booking_settings/data/models/booking_schedule_settings.dart';
import 'package:clover/feature/booking/booking_settings/data/models/booking_weekday.dart';
import 'package:clover/feature/booking/booking_client/data/client_booking_availability.dart';
import 'package:clover/feature/booking/booking_client/data/mock/client_booking_mock_data.dart';
import 'package:clover/feature/booking/booking_client/data/models/client_booking_slot.dart';
import 'package:clover/feature/booking/booking_client/presentation/widget/client_booking_executor_picker.dart';
import 'package:clover/feature/booking/booking_client/presentation/widget/client_booking_service_picker.dart';
import 'package:clover/feature/booking/booking_client/presentation/widget/client_booking_summary.dart';
import 'package:clover/feature/booking/booking_client/presentation/widget/client_booking_time_slots.dart';
import 'package:clover/feature/booking/booking_create/data/models/booking_service.dart';
import 'package:clover/feature/booking/booking_create/data/models/booking_service_executor.dart';
import 'package:clover/feature/booking/shared/presentation/widget/booking_screen_shell.dart';
import 'package:flutter/material.dart';

@RoutePage()
class BookingClientPage extends StatefulWidget {
  const BookingClientPage({
    super.key,
    required this.hostId,
    required this.hostDisplayName,
  });

  final String hostId;
  final String hostDisplayName;

  @override
  State<BookingClientPage> createState() => _BookingClientPageState();
}

class _BookingClientPageState extends State<BookingClientPage> {
  late final List<BookingService> _services = ClientBookingMockData.servicesForHost(widget.hostId);

  BookingService? _selectedService;
  BookingServiceExecutor? _selectedExecutor;
  late DateTime _selectedDay = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  DateTime? _selectedSlotStart;
  String? _conflictMessage;
  bool _submitting = false;

  BookingScheduleSettings get _schedule => BookingScheduleSettingsStore.current;

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  bool get _isRestDay => _schedule.isRestDay(_selectedDay);

  bool get _isExecutorAbsent {
    final executor = _selectedExecutor;
    if (executor == null) return false;
    return _schedule.isExecutorAbsent(executor.id, _selectedDay);
  }

  String? get _dayUnavailableMessage {
    if (_isRestDay) {
      final day = BookingWeekday.fromIso(_selectedDay.weekday);
      final label = day?.fullLabel ?? 'выходной';
      return 'В этот день запись недоступна — $label выходной';
    }
    final executor = _selectedExecutor;
    if (executor != null && _isExecutorAbsent) {
      final note = _schedule.absenceNoteFor(executor.id, _selectedDay);
      if (note != null && note.isNotEmpty) {
        return '${executor.displayName} недоступен в этот день ($note)';
      }
      return '${executor.displayName} недоступен в этот день';
    }
    return null;
  }

  List<BookingServiceExecutor> get _executorsForService {
    final service = _selectedService;
    if (service == null) return const [];
    return ClientBookingMockData.executorsForService(service.id);
  }

  List<ClientBookingSlot> get _slots {
    final service = _selectedService;
    final executor = _selectedExecutor;
    if (service == null || executor == null || _isRestDay || _isExecutorAbsent) return const [];

    final myBookings = ClientBookingMockData.myBookingsOnOtherAccounts(_selectedDay);
    final hostBusy = ClientBookingMockData.executorBusyRanges(_selectedDay, executor.id);

    return ClientBookingAvailability.buildSlots(
      day: _selectedDay,
      service: service,
      myBookings: myBookings,
      hostBusyRanges: hostBusy,
      selectedStart: _selectedSlotStart,
      dayStartHour: _schedule.workStartHour,
      dayEndHour: _schedule.workEndHour,
    );
  }

  bool get _canConfirm {
    if (_selectedService == null || _selectedExecutor == null || _selectedSlotStart == null) return false;
    if (_isRestDay || _isExecutorAbsent) return false;
    final slot = _slots.where((s) => s.status == ClientBookingSlotStatus.selected).firstOrNull;
    return slot != null;
  }

  void _onServiceSelected(BookingService service) {
    final executors = ClientBookingMockData.executorsForService(service.id);
    setState(() {
      _selectedService = service;
      _selectedExecutor = executors.length == 1 ? executors.first : null;
      _selectedSlotStart = null;
      _conflictMessage = null;
    });
  }

  void _onExecutorSelected(BookingServiceExecutor executor) {
    setState(() {
      _selectedExecutor = executor;
      _selectedSlotStart = null;
      _conflictMessage = null;
    });
  }

  void _onDayChanged(DateTime day) {
    setState(() {
      _selectedDay = DateTime(day.year, day.month, day.day);
      _selectedSlotStart = null;
      _conflictMessage = null;
    });
  }

  void _onSlotTap(ClientBookingSlot slot) {
    if (slot.status == ClientBookingSlotStatus.myConflict) {
      setState(() => _conflictMessage = slot.conflictLabel ?? 'Это время пересекается с вашей другой записью');
      return;
    }
    if (slot.status == ClientBookingSlotStatus.hostBusy) {
      final name = _selectedExecutor?.displayName ?? widget.hostDisplayName;
      setState(() => _conflictMessage = 'Это время уже занято у $name');
      return;
    }
    if (!slot.isSelectable) return;

    setState(() {
      _selectedSlotStart = slot.startsAt;
      _conflictMessage = null;
    });
  }

  Future<void> _confirm() async {
    if (!_canConfirm || _submitting) return;

    setState(() => _submitting = true);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    AppSnackBar.show(context, message: 'Запись создана', kind: AppSnackBarKind.success);
    context.router.maybePop(true);
  }

  @override
  Widget build(BuildContext context) {
    final service = _selectedService;
    final dayUnavailableMessage = _dayUnavailableMessage;

    return BookingScreenShell(
      title: 'Запись · ${widget.hostDisplayName}',
      compactBar: true,
      isLoading: _submitting,
      showSave: true,
      canSave: _canConfirm,
      saveLabel: 'Записаться',
      onSaveTap: _confirm,
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 8, 16, BookingScreenShell.scrollBottomGap(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Выберите услугу, мастера, дату и время. Учитываются ваши записи на других аккаунтах.',
              style: AppTextStyle.base(13, color: AppColors.subTextColor, height: 1.35),
            ),
            const SizedBox(height: 16),
            ClientBookingServicePicker(
              services: _services,
              selectedId: service?.id,
              onSelected: _onServiceSelected,
            ),
            if (service != null) ...[
              const SizedBox(height: 20),
              ClientBookingExecutorPicker(
                executors: _executorsForService,
                selectedId: _selectedExecutor?.id,
                onSelected: _onExecutorSelected,
              ),
            ],
            const SizedBox(height: 20),
            AppDatePicker(
              label: 'Дата',
              hint: 'Выберите день',
              value: _selectedDay,
              firstDate: _today,
              lastDate: _schedule.lastBookableDay,
              onChanged: _onDayChanged,
            ),
            if (service != null && _selectedExecutor != null) ...[
              if (dayUnavailableMessage != null) ...[
                const SizedBox(height: 12),
                ClientBookingConflictBanner(message: dayUnavailableMessage),
              ] else ...[
                const SizedBox(height: 20),
                ClientBookingTimeSlots(slots: _slots, onSlotTap: _onSlotTap),
              ],
            ],
            if (_conflictMessage != null) ...[
              const SizedBox(height: 12),
              ClientBookingConflictBanner(message: _conflictMessage!),
            ],
            if (service != null && _selectedExecutor != null && _selectedSlotStart != null) ...[
              const SizedBox(height: 16),
              ClientBookingSummary(
                hostDisplayName: widget.hostDisplayName,
                executor: _selectedExecutor!,
                service: service,
                startsAt: _selectedSlotStart!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    return iterator.current;
  }
}
