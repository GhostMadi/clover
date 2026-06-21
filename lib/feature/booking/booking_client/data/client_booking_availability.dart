import 'package:clover/feature/booking/shared/data/models/client_booking_slot_status.dart';
import 'package:clover/feature/booking/booking_client/data/models/client_booking_slot.dart';
import 'package:clover/feature/booking/booking_client/data/models/client_existing_booking.dart';
import 'package:clover/feature/booking/booking_create/data/models/booking_service.dart';
import 'package:flutter/material.dart';

abstract final class ClientBookingAvailability {
  static bool overlaps({
    required DateTime aStart,
    required DateTime aEnd,
    required DateTime bStart,
    required DateTime bEnd,
  }) {
    return aStart.isBefore(bEnd) && aEnd.isAfter(bStart);
  }

  static DateTime rangeEnd({
    required DateTime start,
    required int durationMinutes,
    required int bufferAfterMinutes,
  }) {
    return start.add(Duration(minutes: durationMinutes + bufferAfterMinutes));
  }

  static ClientBookingSlotStatus resolveStatus({
    required DateTime slotStart,
    required BookingService service,
    required List<ClientExistingBooking> myBookings,
    required List<DateTimeRange> hostBusyRanges,
    DateTime? selectedStart,
  }) {
    if (_isSameMinute(slotStart, selectedStart)) {
      return ClientBookingSlotStatus.selected;
    }

    final slotEnd = rangeEnd(
      start: slotStart,
      durationMinutes: service.durationMinutes,
      bufferAfterMinutes: service.bufferAfterMinutes,
    );

    for (final booking in myBookings) {
      if (overlaps(
        aStart: slotStart,
        aEnd: slotEnd,
        bStart: booking.startsAt,
        bEnd: booking.endsAt,
      )) {
        return ClientBookingSlotStatus.myConflict;
      }
    }

    for (final busy in hostBusyRanges) {
      if (overlaps(
        aStart: slotStart,
        aEnd: slotEnd,
        bStart: busy.start,
        bEnd: busy.end,
      )) {
        return ClientBookingSlotStatus.hostBusy;
      }
    }

    return ClientBookingSlotStatus.available;
  }

  static String? conflictLabelFor({
    required DateTime slotStart,
    required BookingService service,
    required List<ClientExistingBooking> myBookings,
  }) {
    final slotEnd = rangeEnd(
      start: slotStart,
      durationMinutes: service.durationMinutes,
      bufferAfterMinutes: service.bufferAfterMinutes,
    );

    for (final booking in myBookings) {
      if (overlaps(
        aStart: slotStart,
        aEnd: slotEnd,
        bStart: booking.startsAt,
        bEnd: booking.endsAt,
      )) {
        return 'У вас запись: ${booking.conflictLabel}';
      }
    }
    return null;
  }

  static List<ClientBookingSlot> buildSlots({
    required DateTime day,
    required BookingService service,
    required List<ClientExistingBooking> myBookings,
    required List<DateTimeRange> hostBusyRanges,
    DateTime? selectedStart,
    int dayStartHour = 9,
    int dayEndHour = 20,
    int stepMinutes = 30,
  }) {
    final slots = <ClientBookingSlot>[];
    var cursor = DateTime(day.year, day.month, day.day, dayStartHour);
    final end = DateTime(day.year, day.month, day.day, dayEndHour);

    while (cursor.isBefore(end)) {
      final status = resolveStatus(
        slotStart: cursor,
        service: service,
        myBookings: myBookings,
        hostBusyRanges: hostBusyRanges,
        selectedStart: selectedStart,
      );

      final label = status == ClientBookingSlotStatus.myConflict
          ? conflictLabelFor(slotStart: cursor, service: service, myBookings: myBookings)
          : null;

      slots.add(ClientBookingSlot(startsAt: cursor, status: status, conflictLabel: label));
      cursor = cursor.add(Duration(minutes: stepMinutes));
    }

    return slots;
  }

  static bool _isSameMinute(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day && a.hour == b.hour && a.minute == b.minute;
  }
}
