import 'package:clover/feature/_booking_/booking_client/data/models/client_existing_booking.dart';
import 'package:clover/feature/_booking_/booking_create/data/models/booking_service.dart';
import 'package:clover/feature/_booking_/booking_create/data/models/booking_service_executor.dart';
import 'package:flutter/material.dart';

abstract final class ClientBookingMockData {
  static const _executors = [
    BookingServiceExecutor(id: 'exec-1', displayName: 'Алия К.', username: 'aliya_k'),
    BookingServiceExecutor(id: 'exec-2', displayName: 'Марат Т.', username: 'marat_t'),
    BookingServiceExecutor(id: 'exec-3', displayName: 'Diana S.', username: 'diana_s'),
  ];

  /// Какие исполнители могут оказать услугу.
  static const _serviceExecutorIds = {
    '1': ['exec-1', 'exec-2'],
    '2': ['exec-1', 'exec-2'],
    '3': ['exec-3'],
  };

  static List<BookingService> servicesForHost(String hostId) {
    return const [
      BookingService(
        id: '1',
        title: 'Стрижка мужская',
        durationMinutes: 45,
        emojiText: '💈',
        price: 3500,
        maxParticipants: 1,
        bufferAfterMinutes: 15,
        description: 'Модельная стрижка, укладка',
        isActive: true,
      ),
      BookingService(
        id: '2',
        title: 'Консультация',
        durationMinutes: 30,
        emojiText: '💬',
        price: 0,
        maxParticipants: 1,
        bufferAfterMinutes: 0,
        isActive: true,
      ),
      BookingService(
        id: '3',
        title: 'Маникюр',
        durationMinutes: 60,
        emojiText: '💅',
        price: 5000,
        maxParticipants: 1,
        bufferAfterMinutes: 10,
        isActive: true,
      ),
    ];
  }

  static List<BookingServiceExecutor> executorsForService(String serviceId) {
    final ids = _serviceExecutorIds[serviceId] ?? const [];
    return [
      for (final executor in _executors)
        if (ids.contains(executor.id)) executor,
    ];
  }

  static BookingServiceExecutor? executorById(String? id) {
    if (id == null) return null;
    for (final executor in _executors) {
      if (executor.id == id) return executor;
    }
    return null;
  }

  static List<ClientExistingBooking> myBookingsOnOtherAccounts(DateTime day) {
    final base = DateTime(day.year, day.month, day.day);
    return [
      ClientExistingBooking(
        id: 'other-1',
        hostName: 'Studio B',
        startsAt: base.add(const Duration(hours: 12)),
        durationMinutes: 120,
        bufferAfterMinutes: 0,
      ),
    ];
  }

  /// Занято у конкретного исполнителя.
  static List<DateTimeRange> executorBusyRanges(DateTime day, String executorId) {
    final base = DateTime(day.year, day.month, day.day);
    return switch (executorId) {
      'exec-1' => [
        DateTimeRange(
          start: base.add(const Duration(hours: 10)),
          end: base.add(const Duration(hours: 10, minutes: 45)),
        ),
      ],
      'exec-2' => [
        DateTimeRange(
          start: base.add(const Duration(hours: 14)),
          end: base.add(const Duration(hours: 15)),
        ),
      ],
      'exec-3' => [
        DateTimeRange(
          start: base.add(const Duration(hours: 11)),
          end: base.add(const Duration(hours: 12)),
        ),
      ],
      _ => const [],
    };
  }
}
