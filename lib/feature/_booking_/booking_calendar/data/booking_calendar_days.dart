import 'package:clover/feature/_booking_/booking_calendar/data/models/booking_calendar_item.dart';
import 'package:clover/feature/_booking_/booking_list/data/booking_host_inbox.dart';

abstract final class BookingCalendarDays {
  static Map<DateTime, int> countsByDay(List<BookingCalendarItem> items) {
    final map = <DateTime, int>{};
    for (final item in items) {
      final start = item.startsAtDate;
      if (start == null) continue;
      final key = BookingHostInbox.dayKey(start);
      map[key] = (map[key] ?? 0) + 1;
    }
    return map;
  }

  static List<BookingCalendarItem> forDay(List<BookingCalendarItem> items, DateTime day) {
    final key = BookingHostInbox.dayKey(day);
    return items.where((item) {
      final start = item.startsAtDate;
      if (start == null) return false;
      return BookingHostInbox.dayKey(start) == key;
    }).toList(growable: false);
  }
}
