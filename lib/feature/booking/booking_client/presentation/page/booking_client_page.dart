import 'package:auto_route/auto_route.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_date_picker.dart';
import 'package:clover/core/shared/app_snack_bar.dart';
import 'package:clover/feature/booking/booking_client/presentation/cubit/booking_client_cubit.dart';
import 'package:clover/feature/booking/booking_client/presentation/widget/client_booking_comment_field.dart';
import 'package:clover/feature/booking/booking_client/presentation/widget/client_booking_executor_picker.dart';
import 'package:clover/feature/booking/booking_client/presentation/widget/client_booking_service_picker.dart';
import 'package:clover/feature/booking/booking_client/presentation/widget/client_booking_summary.dart';
import 'package:clover/feature/booking/booking_client/presentation/widget/client_booking_time_slots.dart';
import 'package:clover/feature/booking/booking_create/data/repository/booking_services_repository.dart';
import 'package:clover/feature/booking/shared/data/booking_error.dart';
import 'package:clover/feature/booking/shared/presentation/widget/booking_screen_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

@RoutePage()
class BookingClientPage extends StatefulWidget {
  const BookingClientPage({super.key, required this.hostId, required this.hostDisplayName});

  final String hostId;
  final String hostDisplayName;

  @override
  State<BookingClientPage> createState() => _BookingClientPageState();
}

class _BookingClientPageState extends State<BookingClientPage> {
  late final BookingClientCubit _cubit;
  final _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cubit = sl<BookingClientCubit>()
      ..init(hostId: widget.hostId, hostDisplayName: widget.hostDisplayName);
    _commentController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _commentController.dispose();
    _cubit.close();
    super.dispose();
  }

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  List<BookingServiceWithStaff> get _catalog {
    return _cubit.state.maybeMap(ready: (s) => s.catalog, orElse: () => const []);
  }

  List<BookingServiceWithStaff> _executorsForService(String? serviceId) {
    if (serviceId == null) return const [];
    return _catalog.where((c) => c.service.id == serviceId).toList();
  }

  Future<void> _confirm(BookingClientState state) async {
    final ready = state.mapOrNull(ready: (s) => s);
    if (ready == null) return;

    final ok = await _cubit.confirm(
      clientComment: _commentController.text.trim().isEmpty ? null : _commentController.text.trim(),
    );
    if (!mounted) return;

    if (ok) {
      AppSnackBar.show(context, message: 'Запись создана', kind: AppSnackBarKind.success);
      context.router.maybePop(true);
      return;
    }

    final message = _cubit.state.maybeMap(ready: (s) => s.conflictMessage, orElse: () => null);
    if (message != null) {
      AppSnackBar.show(
        context,
        message: message.contains('BookingException') ? BookingException.from(message).userMessage : message,
        kind: AppSnackBarKind.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BookingClientCubit, BookingClientState>(
      bloc: _cubit,
      builder: (context, state) {
        final ready = state.mapOrNull(ready: (s) => s);
        final service = ready?.selectedService;
        final executor = ready?.selectedExecutor;
        final canConfirm = ready != null &&
            service != null &&
            executor != null &&
            ready.selectedSlotStart != null &&
            !ready.isSubmitting;

        return BookingScreenShell(
          title: 'Запись · ${widget.hostDisplayName}',
          compactBar: true,
          isLoading: state.maybeMap(loading: (_) => true, orElse: () => ready?.isSubmitting ?? false),
          showSave: ready != null,
          canSave: canConfirm,
          saveLabel: 'Записаться',
          onSaveTap: () => _confirm(state),
          body: state.maybeMap(
            loading: (_) => const Center(child: CircularProgressIndicator()),
            error: (s) => Center(child: Text(s.message)),
            orElse: () {
              if (ready == null) return const SizedBox.shrink();

              final services = [for (final entry in ready.catalog) entry.service];
              final executors = _executorsForService(service?.id).firstOrNull?.staff ?? const [];

              String? dayUnavailableMessage;
              final reason = ready.dayUnavailableReason;
              if (reason != null && reason.isNotEmpty) {
                dayUnavailableMessage = switch (reason) {
                  'rest_day' => 'В этот день запись недоступна — выходной',
                  'executor_absent' => '${executor?.displayName ?? 'Мастер'} недоступен в этот день',
                  _ => 'В этот день запись недоступна',
                };
              }

              return SingleChildScrollView(
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
                      services: services,
                      selectedId: service?.id,
                      onSelected: _cubit.selectService,
                    ),
                    if (service != null) ...[
                      const SizedBox(height: 20),
                      ClientBookingExecutorPicker(
                        executors: executors,
                        selectedId: executor?.id,
                        onSelected: _cubit.selectExecutor,
                      ),
                    ],
                    const SizedBox(height: 20),
                    AppDatePicker(
                      label: 'Дата',
                      hint: 'Выберите день',
                      value: ready.selectedDay,
                      firstDate: _today,
                      lastDate: ready.schedule.lastBookableDay,
                      onChanged: _cubit.selectDay,
                    ),
                    if (service != null && executor != null) ...[
                      if (dayUnavailableMessage != null) ...[
                        const SizedBox(height: 12),
                        ClientBookingConflictBanner(message: dayUnavailableMessage),
                      ] else if (ready.isLoadingSlots) ...[
                        const SizedBox(height: 20),
                        const Center(child: CircularProgressIndicator()),
                      ] else ...[
                        const SizedBox(height: 20),
                        ClientBookingTimeSlots(slots: ready.slots, onSlotTap: _cubit.selectSlot),
                      ],
                    ],
                    if (ready.conflictMessage != null) ...[
                      const SizedBox(height: 12),
                      ClientBookingConflictBanner(message: ready.conflictMessage!),
                    ],
                    if (service != null && executor != null) ...[
                      const SizedBox(height: 20),
                      ClientBookingCommentField(controller: _commentController),
                    ],
                    if (service != null && executor != null && ready.selectedSlotStart != null) ...[
                      const SizedBox(height: 16),
                      ClientBookingSummary(
                        hostDisplayName: widget.hostDisplayName,
                        executor: executor,
                        service: service,
                        startsAt: ready.selectedSlotStart!,
                        clientComment: _commentController.text,
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        );
      },
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
