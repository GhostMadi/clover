import 'package:clover/feature/booking/booking_client/data/mock/client_booking_submissions_store.dart';
import 'package:clover/feature/booking/shared/data/models/booking_status.dart';
import 'package:clover/feature/booking/my_bookings/data/models/my_booking_item.dart';

abstract final class MyBookingsMockData {
  static List<MyBookingItem> get items {
    return [...ClientBookingSubmissionsStore.items, ..._seedItems];
  }

  static List<MyBookingItem> get _seedItems {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final yesterday = today.subtract(const Duration(days: 1));
    final lastWeek = today.subtract(const Duration(days: 5));

    return [
      MyBookingItem(
        id: 'mb-1',
        hostId: 'host-barber',
        hostDisplayName: 'Barber Studio',
        hostUsername: 'barber_studio',
        serviceTitle: 'Стрижка мужская',
        serviceEmoji: '💈',
        durationMinutes: 45,
        price: 3500,
        executorName: 'Марат Т.',
        startsAt: _format(tomorrow, 11, 0),
        createdAt: _format(today, 9, 30),
        status: BookingStatus.confirmed,
        notes: 'Коротко сбоку',
      ),
      MyBookingItem(
        id: 'mb-2',
        hostId: 'host-nails',
        hostDisplayName: 'Nail Room',
        hostUsername: 'nail_room',
        serviceTitle: 'Маникюр',
        serviceEmoji: '💅',
        durationMinutes: 60,
        price: 5000,
        executorName: 'Diana S.',
        startsAt: _format(today, 16, 0),
        createdAt: _format(yesterday, 14, 10),
        status: BookingStatus.confirmed,
      ),
      MyBookingItem(
        id: 'mb-3',
        hostId: 'host-studio-b',
        hostDisplayName: 'Studio B',
        hostUsername: 'studio_b',
        serviceTitle: 'Окрашивание',
        serviceEmoji: '✨',
        durationMinutes: 120,
        price: 15000,
        executorName: 'Алия К.',
        startsAt: _format(yesterday, 12, 0),
        createdAt: _format(lastWeek, 10, 0),
        status: BookingStatus.completed,
      ),
      MyBookingItem(
        id: 'mb-4',
        hostId: 'host-barber',
        hostDisplayName: 'Barber Studio',
        hostUsername: 'barber_studio',
        serviceTitle: 'Консультация',
        serviceEmoji: '💬',
        durationMinutes: 30,
        price: 0,
        executorName: 'Алия К.',
        startsAt: _format(lastWeek, 15, 30),
        createdAt: _format(lastWeek.subtract(const Duration(days: 3)), 18, 0),
        status: BookingStatus.completed,
      ),
      MyBookingItem(
        id: 'mb-5',
        hostId: 'host-spa',
        hostDisplayName: 'Urban Spa',
        hostUsername: 'urban_spa',
        serviceTitle: 'Массаж',
        serviceEmoji: '💆',
        durationMinutes: 60,
        price: 8000,
        startsAt: _format(today.subtract(const Duration(days: 14)), 18, 0),
        createdAt: _format(today.subtract(const Duration(days: 20)), 11, 0),
        status: BookingStatus.cancelled,
        notes: 'Перенесли на другой день',
      ),
    ];
  }

  static String _format(DateTime date, int hour, int minute) {
    final y = date.year;
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    final h = hour.toString().padLeft(2, '0');
    final min = minute.toString().padLeft(2, '0');
    return '$y-$m-${d}T$h:$min:00';
  }
}
