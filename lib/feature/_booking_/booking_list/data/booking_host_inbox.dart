import 'package:clover/feature/_booking_/booking_list/data/models/booking_list_item.dart';
import 'package:clover/feature/_booking_/shared/data/models/booking_status.dart';

enum BookingHostInboxTab {
  pending,
  inChair,
  upcoming,
  archive,
}

extension BookingHostInboxTabX on BookingHostInboxTab {
  String get shortLabel => switch (this) {
        BookingHostInboxTab.pending => 'Подтвердить',
        BookingHostInboxTab.inChair => 'Сейчас',
        BookingHostInboxTab.upcoming => 'Предстоящие',
        BookingHostInboxTab.archive => 'Архив',
      };

  String get label => switch (this) {
        BookingHostInboxTab.pending => 'Надо подтвердить',
        BookingHostInboxTab.inChair => 'Сейчас в кресле',
        BookingHostInboxTab.upcoming => 'Предстоящие',
        BookingHostInboxTab.archive => 'Прошедшие и архив',
      };
}

/// Разбивка host-записей по 4 табам inbox.
abstract final class BookingHostInbox {
  static DateTime dayKey(DateTime value) {
    final local = value.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  static bool isPending(BookingListItem item) => item.status == BookingStatus.pending;

  static bool isInChair(BookingListItem item, {DateTime? now}) {
    final at = now ?? DateTime.now();
    if (item.status == BookingStatus.clientArrived || item.status == BookingStatus.inProgress) {
      return true;
    }
    if (item.status != BookingStatus.confirmed) return false;
    final start = item.startsAtDate;
    final end = item.endsAtDate;
    if (start == null || end == null) return false;
    return !start.isAfter(at) && end.isAfter(at);
  }

  static bool isUpcoming(BookingListItem item, {DateTime? now}) {
    if (item.status != BookingStatus.confirmed) return false;
    final start = item.startsAtDate;
    if (start == null) return false;
    return start.isAfter(now ?? DateTime.now());
  }

  static bool isForgotten(BookingListItem item, {DateTime? now}) {
    final at = now ?? DateTime.now();
    final end = item.endsAtDate;
    if (end == null || !end.isBefore(at)) return false;
    return item.status == BookingStatus.confirmed ||
        item.status == BookingStatus.clientArrived ||
        item.status == BookingStatus.inProgress;
  }

  static bool isHistory(BookingListItem item) =>
      item.status == BookingStatus.completed || item.status == BookingStatus.noShow;

  static bool isCancelled(BookingListItem item) => item.status == BookingStatus.cancelled;

  static List<BookingListItem> pending(List<BookingListItem> items) {
    final list = items.where(isPending).toList(growable: false);
    return List<BookingListItem>.from(list)
      ..sort((a, b) {
        final aAt = a.createdAtDate ?? a.startsAtDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bAt = b.createdAtDate ?? b.startsAtDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bAt.compareTo(aAt);
      });
  }

  static List<BookingListItem> inChair(List<BookingListItem> items, {DateTime? now}) {
    final at = now ?? DateTime.now();
    final list = items.where((item) => isInChair(item, now: at)).toList(growable: false);
    return List<BookingListItem>.from(list)
      ..sort((a, b) {
        final aAt = a.startsAtDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bAt = b.startsAtDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        return aAt.compareTo(bAt);
      });
  }

  static List<BookingListItem> upcoming(List<BookingListItem> items, {DateTime? now, DateTime? day}) {
    final at = now ?? DateTime.now();
    var list = items.where((item) => isUpcoming(item, now: at)).toList(growable: false);
    if (day != null) {
      final key = dayKey(day);
      list = list.where((item) {
        final start = item.startsAtDate;
        if (start == null) return false;
        return dayKey(start) == key;
      }).toList(growable: false);
    }
    return List<BookingListItem>.from(list)
      ..sort((a, b) {
        final aAt = a.startsAtDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bAt = b.startsAtDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        return aAt.compareTo(bAt);
      });
  }

  static List<BookingListItem> forgotten(List<BookingListItem> items, {DateTime? now}) {
    final at = now ?? DateTime.now();
    final list = items.where((item) => isForgotten(item, now: at)).toList(growable: false);
    return List<BookingListItem>.from(list)
      ..sort((a, b) {
        final aAt = a.endsAtDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bAt = b.endsAtDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bAt.compareTo(aAt);
      });
  }

  static List<BookingListItem> history(List<BookingListItem> items) {
    final list = items.where(isHistory).toList(growable: false);
    return List<BookingListItem>.from(list)
      ..sort((a, b) {
        final aAt = a.startsAtDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bAt = b.startsAtDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bAt.compareTo(aAt);
      });
  }

  static List<BookingListItem> cancelled(List<BookingListItem> items) {
    final list = items.where(isCancelled).toList(growable: false);
    return List<BookingListItem>.from(list)
      ..sort((a, b) {
        final aAt = a.startsAtDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bAt = b.startsAtDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bAt.compareTo(aAt);
      });
  }

  /// Дни для горизонтальной ленты: сегодня + дни, где есть upcoming.
  static List<DateTime> upcomingDayOptions(List<BookingListItem> items, {DateTime? now}) {
    final at = now ?? DateTime.now();
    final today = dayKey(at);
    final days = <DateTime>{today};
    for (final item in upcoming(items, now: at)) {
      final start = item.startsAtDate;
      if (start == null) continue;
      days.add(dayKey(start));
    }
    final sorted = days.toList()..sort();
    return sorted;
  }

  static Map<DateTime, List<BookingListItem>> groupByDay(List<BookingListItem> items) {
    final map = <DateTime, List<BookingListItem>>{};
    for (final item in items) {
      final start = item.startsAtDate;
      if (start == null) continue;
      final key = dayKey(start);
      (map[key] ??= <BookingListItem>[]).add(item);
    }
    final keys = map.keys.toList()..sort((a, b) => b.compareTo(a));
    return {for (final key in keys) key: map[key]!};
  }

  static String dayStripLabel(DateTime day, {DateTime? now}) {
    final today = dayKey(now ?? DateTime.now());
    final key = dayKey(day);
    if (key == today) return 'Сегодня';
    if (key == today.add(const Duration(days: 1))) return 'Завтра';
    const weekdays = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    return weekdays[key.weekday - 1];
  }

  static String archiveDayLabel(DateTime day, {DateTime? now}) {
    final today = dayKey(now ?? DateTime.now());
    final key = dayKey(day);
    if (key == today) return 'Сегодня';
    if (key == today.subtract(const Duration(days: 1))) return 'Вчера';
    const months = [
      'января',
      'февраля',
      'марта',
      'апреля',
      'мая',
      'июня',
      'июля',
      'августа',
      'сентября',
      'октября',
      'ноября',
      'декабря',
    ];
    const weekdays = ['Понедельник', 'Вторник', 'Среда', 'Четверг', 'Пятница', 'Суббота', 'Воскресенье'];
    return '${weekdays[key.weekday - 1]}, ${key.day} ${months[key.month - 1]}';
  }
}
