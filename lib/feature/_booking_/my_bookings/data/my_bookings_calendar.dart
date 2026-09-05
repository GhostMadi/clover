import 'package:clover/feature/_booking_/booking_list/data/booking_host_inbox.dart';
import 'package:clover/feature/_booking_/my_bookings/data/models/my_booking_item.dart';

/// Группировка клиентских записей по дням.
abstract final class MyBookingsCalendar {
  static Map<DateTime, int> countsByDay(List<MyBookingItem> items) {
    final map = <DateTime, int>{};
    for (final item in items) {
      final start = item.startsAtDate;
      if (start == null) continue;
      final key = BookingHostInbox.dayKey(start);
      map[key] = (map[key] ?? 0) + 1;
    }
    return map;
  }

  static List<MyBookingItem> forDay(List<MyBookingItem> items, DateTime day) {
    final key = BookingHostInbox.dayKey(day);
    return items.where((item) {
      final start = item.startsAtDate;
      if (start == null) return false;
      return BookingHostInbox.dayKey(start) == key;
    }).toList(growable: false);
  }
}
