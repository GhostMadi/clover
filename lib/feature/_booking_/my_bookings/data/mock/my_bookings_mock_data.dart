import 'package:clover/feature/_booking_/booking_client/data/mock/client_booking_submissions_store.dart';
import 'package:clover/feature/_booking_/booking_list/data/booking_host_inbox.dart';
import 'package:clover/feature/_booking_/my_bookings/data/models/my_booking_item.dart';
import 'package:clover/feature/_booking_/shared/data/models/booking_status.dart';

abstract final class MyBookingsMockData {
  static List<MyBookingItem> get items => [...ClientBookingSubmissionsStore.items, ..._seedItems];

  static List<MyBookingItem> itemsInRange(DateTime from, DateTime to) {
    final start = BookingHostInbox.dayKey(from);
    final end = BookingHostInbox.dayKey(to).add(const Duration(days: 1)).subtract(const Duration(seconds: 1));
    return items.where((item) {
      final at = item.startsAtDate;
      if (at == null) return false;
      return !at.isBefore(start) && !at.isAfter(end);
    }).toList(growable: false);
  }

  static List<MyBookingItem> get _seedItems {
    final now = DateTime.now();
    final today = BookingHostInbox.dayKey(now);

    return [
      MyBookingItem(
        id: 'mb-today',
        hostId: 'host-nails',
        hostDisplayName: 'Nail Room',
        hostUsername: 'nail_room',
        serviceTitle: 'Маникюр',
        serviceEmoji: '💅',
        durationMinutes: 60,
        price: 5000,
        executorName: 'Diana S.',
        startsAt: _iso(today, 16, 30),
        createdAt: _iso(today.subtract(const Duration(days: 1)), 14, 10),
        status: BookingStatus.confirmed,
      ),
      MyBookingItem(
        id: 'mb-tomorrow',
        hostId: 'host-barber',
        hostDisplayName: 'Barber Studio',
        hostUsername: 'barber_studio',
        serviceTitle: 'Стрижка мужская',
        serviceEmoji: '💈',
        durationMinutes: 45,
        price: 3500,
        executorName: 'Марат Т.',
        startsAt: _iso(today.add(const Duration(days: 1)), 11, 0),
        createdAt: _iso(today, 9, 30),
        status: BookingStatus.confirmed,
        notes: 'Коротко сбоку',
      ),
      MyBookingItem(
        id: 'mb-plus-4',
        hostId: 'host-studio-b',
        hostDisplayName: 'Studio B',
        hostUsername: 'studio_b',
        serviceTitle: 'Окрашивание',
        serviceEmoji: '✨',
        durationMinutes: 120,
        price: 15000,
        executorName: 'Алия К.',
        startsAt: _iso(today.add(const Duration(days: 4)), 12, 0),
        createdAt: _iso(today, 10, 0),
        status: BookingStatus.confirmed,
      ),
      MyBookingItem(
        id: 'mb-plus-6',
        hostId: 'host-spa',
        hostDisplayName: 'Urban Spa',
        hostUsername: 'urban_spa',
        serviceTitle: 'Массаж',
        serviceEmoji: '💆',
        durationMinutes: 60,
        price: 8000,
        executorName: 'Айгуль Н.',
        startsAt: _iso(today.add(const Duration(days: 6)), 18, 0),
        createdAt: _iso(today, 11, 0),
        status: BookingStatus.confirmed,
      ),
      MyBookingItem(
        id: 'mb-yesterday',
        hostId: 'host-barber',
        hostDisplayName: 'Barber Studio',
        hostUsername: 'barber_studio',
        serviceTitle: 'Консультация',
        serviceEmoji: '💬',
        durationMinutes: 30,
        price: 0,
        executorName: 'Алия К.',
        startsAt: _iso(today.subtract(const Duration(days: 1)), 15, 30),
        createdAt: _iso(today.subtract(const Duration(days: 4)), 18, 0),
        status: BookingStatus.completed,
      ),
      MyBookingItem(
        id: 'mb-cancelled',
        hostId: 'host-spa',
        hostDisplayName: 'Urban Spa',
        hostUsername: 'urban_spa',
        serviceTitle: 'Массаж',
        serviceEmoji: '💆',
        durationMinutes: 60,
        price: 8000,
        startsAt: _iso(today.subtract(const Duration(days: 3)), 18, 0),
        createdAt: _iso(today.subtract(const Duration(days: 10)), 11, 0),
        status: BookingStatus.cancelled,
        notes: 'Перенесли на другой день',
      ),
    ];
  }

  static String _iso(DateTime date, int hour, int minute) {
    final local = DateTime(date.year, date.month, date.day, hour, minute);
    return local.toIso8601String();
  }
}
