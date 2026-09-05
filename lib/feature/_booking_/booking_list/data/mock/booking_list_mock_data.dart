import 'package:clover/feature/_booking_/booking_list/data/booking_host_inbox.dart';
import 'package:clover/feature/_booking_/booking_list/data/models/booking_list_item.dart';
import 'package:clover/feature/_booking_/shared/data/models/booking_status.dart';

/// Demo-данные inbox хоста: несколько дней месяца для календаря.
abstract final class BookingListMockData {
  static List<BookingListItem> get items => _build();

  static List<BookingListItem> itemsInRange(DateTime from, DateTime to) {
    final start = BookingHostInbox.dayKey(from);
    final end = BookingHostInbox.dayKey(to).add(const Duration(days: 1)).subtract(const Duration(seconds: 1));
    return items.where((item) {
      final at = item.startsAtDate;
      if (at == null) return false;
      return !at.isBefore(start) && !at.isAfter(end);
    }).toList(growable: false);
  }

  static List<BookingListItem> _build() {
    final now = DateTime.now();
    final today = BookingHostInbox.dayKey(now);
    final inChairStart = now.subtract(const Duration(minutes: 20));

    return [
      // Сегодня: in-chair + confirmed вечером
      BookingListItem(
        id: 'mock-confirmed-today-late',
        clientName: 'Марат Т.',
        clientPhone: '+7 701 555 12 34',
        clientUsername: 'marat_t',
        serviceTitle: 'Консультация',
        serviceEmoji: '💬',
        durationMinutes: 30,
        price: 0,
        executorName: 'Алия К.',
        startsAt: _iso(today, 18, 30),
        createdAt: _iso(today, 9, 15),
        status: BookingStatus.confirmed,
      ),
      BookingListItem(
        id: 'mock-in-chair',
        clientName: 'Алия К.',
        clientPhone: '+7 777 123 45 67',
        clientUsername: 'aliya_k',
        serviceTitle: 'Стрижка мужская',
        serviceEmoji: '💈',
        durationMinutes: 60,
        price: 3500,
        executorName: 'Марат Т.',
        startsAt: inChairStart.toIso8601String(),
        createdAt: _iso(today.subtract(const Duration(days: 1)), 18, 20),
        status: BookingStatus.inProgress,
        notes: 'Сейчас в кресле',
      ),
      BookingListItem(
        id: 'mock-confirmed-today',
        clientName: 'Diana S.',
        clientPhone: '+7 708 900 11 22',
        clientUsername: 'diana_s',
        serviceTitle: 'Маникюр',
        serviceEmoji: '💅',
        durationMinutes: 60,
        price: 5000,
        executorName: 'Diana S.',
        startsAt: _iso(today, 19, 0),
        createdAt: _iso(today, 11, 40),
        status: BookingStatus.confirmed,
      ),
      // Завтра — 2 записи
      BookingListItem(
        id: 'mock-tomorrow-1',
        clientName: 'Ерлан Б.',
        clientPhone: '+7 747 333 44 55',
        clientUsername: 'erlan_b',
        serviceTitle: 'Стрижка мужская',
        serviceEmoji: '💈',
        durationMinutes: 45,
        price: 3500,
        executorName: 'Марат Т.',
        startsAt: _iso(today.add(const Duration(days: 1)), 11, 0),
        createdAt: _iso(today, 16, 5),
        status: BookingStatus.confirmed,
      ),
      BookingListItem(
        id: 'mock-tomorrow-2',
        clientName: 'Сауле Н.',
        clientPhone: '+7 705 222 33 44',
        clientUsername: 'saule_n',
        serviceTitle: 'Укладка',
        serviceEmoji: '✨',
        durationMinutes: 40,
        price: 4500,
        executorName: 'Алия К.',
        startsAt: _iso(today.add(const Duration(days: 1)), 15, 30),
        createdAt: _iso(today, 12, 0),
        status: BookingStatus.confirmed,
      ),
      // +3 дня
      BookingListItem(
        id: 'mock-plus-3',
        clientName: 'Айдана Р.',
        clientPhone: '+7 702 111 22 33',
        clientUsername: 'aidana_r',
        serviceTitle: 'Окрашивание',
        serviceEmoji: '✨',
        durationMinutes: 90,
        price: 12000,
        executorName: 'Алия К.',
        startsAt: _iso(today.add(const Duration(days: 3)), 10, 0),
        createdAt: _iso(today, 8, 0),
        status: BookingStatus.confirmed,
      ),
      // +5 дней — 2 записи
      BookingListItem(
        id: 'mock-plus-5-a',
        clientName: 'Нурлан К.',
        clientPhone: '+7 701 999 88 77',
        clientUsername: 'nurlan_k',
        serviceTitle: 'Стрижка',
        serviceEmoji: '💈',
        durationMinutes: 45,
        price: 3500,
        executorName: 'Марат Т.',
        startsAt: _iso(today.add(const Duration(days: 5)), 12, 0),
        createdAt: _iso(today, 14, 0),
        status: BookingStatus.confirmed,
      ),
      BookingListItem(
        id: 'mock-plus-5-b',
        clientName: 'Жанар М.',
        clientPhone: '+7 707 444 55 66',
        clientUsername: 'zhanar_m',
        serviceTitle: 'Маникюр',
        serviceEmoji: '💅',
        durationMinutes: 60,
        price: 5000,
        executorName: 'Diana S.',
        startsAt: _iso(today.add(const Duration(days: 5)), 16, 0),
        createdAt: _iso(today, 15, 0),
        status: BookingStatus.confirmed,
      ),
      // +8 дней
      BookingListItem(
        id: 'mock-plus-8',
        clientName: 'Timur A.',
        clientPhone: '+7 708 333 22 11',
        clientUsername: 'timur_a',
        serviceTitle: 'Борода',
        serviceEmoji: '🧔',
        durationMinutes: 30,
        price: 2500,
        executorName: 'Марат Т.',
        startsAt: _iso(today.add(const Duration(days: 8)), 14, 0),
        createdAt: _iso(today, 17, 0),
        status: BookingStatus.confirmed,
      ),
      // Вчера — незакрытая (forgotten)
      BookingListItem(
        id: 'mock-forgotten',
        clientName: 'Камила С.',
        clientPhone: '+7 705 777 66 55',
        clientUsername: 'kamila_s',
        serviceTitle: 'Стрижка',
        serviceEmoji: '💈',
        durationMinutes: 45,
        price: 3500,
        executorName: 'Марат Т.',
        startsAt: _iso(today.subtract(const Duration(days: 1)), 16, 0),
        createdAt: _iso(today.subtract(const Duration(days: 2)), 10, 0),
        status: BookingStatus.confirmed,
      ),
      // Архив
      BookingListItem(
        id: 'mock-completed',
        clientName: 'Сауле Н.',
        clientPhone: '+7 705 222 33 44',
        clientUsername: 'saule_n',
        serviceTitle: 'Окрашивание',
        serviceEmoji: '✨',
        durationMinutes: 90,
        price: 12000,
        executorName: 'Алия К.',
        startsAt: _iso(today.subtract(const Duration(days: 4)), 15, 0),
        createdAt: _iso(today.subtract(const Duration(days: 6)), 12, 0),
        status: BookingStatus.completed,
      ),
      BookingListItem(
        id: 'mock-cancelled',
        clientName: 'Aruzhan T.',
        clientPhone: '+7 747 111 00 99',
        clientUsername: 'aruzhan_t',
        serviceTitle: 'Массаж',
        serviceEmoji: '💆',
        durationMinutes: 60,
        price: 8000,
        executorName: 'Алия К.',
        startsAt: _iso(today.subtract(const Duration(days: 2)), 13, 0),
        createdAt: _iso(today.subtract(const Duration(days: 5)), 9, 0),
        status: BookingStatus.cancelled,
      ),
    ];
  }

  static String _iso(DateTime date, int hour, int minute) {
    final local = DateTime(date.year, date.month, date.day, hour, minute);
    return local.toIso8601String();
  }
}
