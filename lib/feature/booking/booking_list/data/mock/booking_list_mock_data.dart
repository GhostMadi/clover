import 'package:clover/feature/booking/booking_list/data/models/booking_list_item.dart';
import 'package:clover/feature/booking/shared/data/models/booking_status.dart';

/// Временные данные для вёрстки списка записей.
abstract final class BookingListMockData {
  static List<BookingListItem> get items {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final yesterday = today.subtract(const Duration(days: 1));

    return [
      BookingListItem(
        id: '1',
        clientName: 'Алия К.',
        clientPhone: '+7 777 123 45 67',
        clientUsername: 'aliya_k',
        serviceTitle: 'Стрижка мужская',
        serviceEmoji: '💈',
        durationMinutes: 45,
        price: 3500,
        executorName: 'Марат Т.',
        startsAt: _format(today, 10, 30),
        createdAt: _format(yesterday, 18, 20),
        status: BookingStatus.confirmed,
        notes: 'Хочу коротко сбоку, без фейда',
      ),
      BookingListItem(
        id: '2',
        clientName: 'Марат Т.',
        clientPhone: '+7 701 555 12 34',
        clientUsername: 'marat_t',
        serviceTitle: 'Консультация',
        serviceEmoji: '💬',
        durationMinutes: 30,
        price: 0,
        executorName: 'Алия К.',
        startsAt: _format(today, 14, 0),
        createdAt: _format(today, 9, 15),
        status: BookingStatus.pending,
      ),
      BookingListItem(
        id: '3',
        clientName: 'Diana S.',
        clientPhone: '+7 708 900 11 22',
        clientUsername: 'diana_s',
        serviceTitle: 'Маникюр',
        serviceEmoji: '💅',
        durationMinutes: 60,
        price: 5000,
        executorName: 'Diana S.',
        startsAt: _format(today, 17, 30),
        createdAt: _format(today, 11, 40),
        status: BookingStatus.completed,
        notes: 'Покрытие nude, без дизайна',
      ),
      BookingListItem(
        id: '4',
        clientName: 'Ерлан Б.',
        clientPhone: '+7 747 333 44 55',
        clientUsername: 'erlan_b',
        serviceTitle: 'Стрижка мужская',
        serviceEmoji: '💈',
        durationMinutes: 45,
        price: 3500,
        executorName: 'Марат Т.',
        startsAt: _format(tomorrow, 11, 0),
        createdAt: _format(today, 16, 5),
        status: BookingStatus.confirmed,
      ),
      BookingListItem(
        id: '5',
        clientName: 'Сауле Н.',
        clientPhone: '+7 705 222 33 44',
        clientUsername: 'saule_n',
        serviceTitle: 'Окрашивание',
        serviceEmoji: '✨',
        durationMinutes: 90,
        price: 12000,
        executorName: 'Алия К.',
        participantsCount: 1,
        startsAt: _format(yesterday, 15, 0),
        createdAt: _format(yesterday.subtract(const Duration(days: 2)), 12, 0),
        status: BookingStatus.completed,
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
