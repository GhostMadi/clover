import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_date_picker.dart';
import 'package:clover/feature/_booking_/booking_client/data/models/client_booking_slot.dart';
import 'package:clover/feature/_booking_/shared/presentation/cubit/booking_reschedule_cubit.dart';
import 'package:clover/feature/_booking_/shared/presentation/widget/booking_service_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Shared availability picker body for host and client reschedule sheets.
class BookingRescheduleSheet extends StatefulWidget {
  const BookingRescheduleSheet({
    super.key,
    required this.hostId,
    required this.serviceId,
    required this.staffId,
    required this.bookingId,
    this.initialDay,
  });

  final String hostId;
  final String serviceId;
  final String staffId;
  final String bookingId;
  final DateTime? initialDay;

  @override
  State<BookingRescheduleSheet> createState() => _BookingRescheduleSheetState();
}

class _BookingRescheduleSheetState extends State<BookingRescheduleSheet> {
  late final BookingRescheduleCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = sl<BookingRescheduleCubit>();
    _cubit.load(
      hostId: widget.hostId,
      serviceId: widget.serviceId,
      staffId: widget.staffId,
      bookingId: widget.bookingId,
      initialDay: widget.initialDay,
    );
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BookingRescheduleCubit, BookingRescheduleState>(
      bloc: _cubit,
      builder: (context, state) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final selected = state.selectedStartsAt;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView(
                children: [
                  AppDatePicker(
                    label: 'Дата',
                    hint: 'Выберите день',
                    value: state.day,
                    firstDate: today,
                    lastDate: today.add(const Duration(days: 90)),
                    service: kBookingService,
                    onChanged: _cubit.selectDay,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Доступное время',
                    style: AppTextStyle.base(
                      14,
                      color: context.colors.subTextColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (state.loading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: BookingLoader(size: 28),
                    )
                  else if (state.slots.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        state.dayUnavailableReason ??
                            'На этот день нет свободного времени',
                        textAlign: TextAlign.center,
                        style: AppTextStyle.base(
                          14,
                          color: context.colors.subTextColor,
                          height: 1.4,
                        ),
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final slot in state.slots)
                          _AvailableSlotChip(
                            slot: slot,
                            selected:
                                selected != null &&
                                _sameMinute(selected, slot.startsAt),
                            onTap: () => _cubit.selectSlot(slot.startsAt),
                          ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            BookingPrimaryButton(
              text: 'Сохранить',
              height: 48,
              isExpanded: true,
              interactive: selected != null,
              onTap: selected == null
                  ? null
                  : () => Navigator.of(context).pop(selected),
            ),
          ],
        );
      },
    );
  }

  bool _sameMinute(DateTime a, DateTime b) =>
      a.year == b.year &&
      a.month == b.month &&
      a.day == b.day &&
      a.hour == b.hour &&
      a.minute == b.minute;
}

class _AvailableSlotChip extends StatelessWidget {
  const _AvailableSlotChip({
    required this.slot,
    required this.selected,
    required this.onTap,
  });

  final ClientBookingSlot slot;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = bookingServiceAccent(context.colors);
    final background = selected ? accent.cta : context.colors.surface;
    final foreground = selected
        ? accent.ctaForeground
        : context.colors.textColor;
    final border = selected ? accent.cta : accent.ctaBorder;

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border),
          ),
          child: Text(
            slot.timeLabel,
            style: AppTextStyle.base(
              13,
              color: foreground,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
