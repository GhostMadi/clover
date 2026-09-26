import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/locale/app_date_format.dart';
import 'package:clover/core/locale/app_locale_cubit.dart';
import 'package:clover/feature/_booking_/booking_list/data/models/booking_list_item.dart';
import 'package:clover/feature/_booking_/shared/data/models/booking_status.dart';
import 'package:clover/l10n/app_localizations.dart';

enum BookingHostInboxTab {
  inChair,
  upcoming,
  archive,
}

extension BookingHostInboxTabX on BookingHostInboxTab {
  String shortLabel(AppLocalizations l10n) => switch (this) {
        BookingHostInboxTab.inChair => l10n.booking_inbox_now,
        BookingHostInboxTab.upcoming => l10n.booking_inbox_upcoming,
        BookingHostInboxTab.archive => l10n.booking_inbox_archive,
      };

  String label(AppLocalizations l10n) => switch (this) {
        BookingHostInboxTab.inChair => l10n.booking_inbox_now_chair,
        BookingHostInboxTab.upcoming => l10n.booking_inbox_upcoming,
        BookingHostInboxTab.archive => l10n.booking_inbox_past_archive,
      };
}

/// Разбивка host-записей по 3 табам inbox.
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
    final start = item.startsAtDate;
    if (start == null) return false;
    if (!start.isAfter(now ?? DateTime.now())) return false;
    return item.status == BookingStatus.confirmed || item.status == BookingStatus.pending;
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

  /// Активные записи по дням для календаря (pending, сейчас, предстоящие, незакрытые).
  static Map<DateTime, int> overviewCountsByDay(List<BookingListItem> items, {DateTime? now}) {
    final at = now ?? DateTime.now();
    final map = <DateTime, int>{};

    void bump(BookingListItem item) {
      final start = item.startsAtDate;
      if (start == null) return;
      final key = dayKey(start);
      map[key] = (map[key] ?? 0) + 1;
    }

    for (final item in items) {
      if (isPending(item) ||
          isInChair(item, now: at) ||
          isUpcoming(item, now: at) ||
          isForgotten(item, now: at)) {
        bump(item);
      }
    }
    return map;
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
    final dates = AppDateFormat.current();
    final l10n = lookupAppLocalizations(sl<AppLocaleCubit>().state.locale);
    final today = dayKey(now ?? DateTime.now());
    final key = dayKey(day);
    if (key == today) return l10n.common_today;
    if (key == today.add(const Duration(days: 1))) return l10n.common_tomorrow;
    return dates.shortWeekday(key);
  }

  /// Короткий месяц для чипа ленты: «20 сен».
  static String dayStripDayWithMonth(DateTime day) {
    final key = dayKey(day);
    return AppDateFormat.current().dayMonth(key);
  }

  static String archiveDayLabel(DateTime day, {DateTime? now}) {
    final dates = AppDateFormat.current();
    final l10n = lookupAppLocalizations(sl<AppLocaleCubit>().state.locale);
    final today = dayKey(now ?? DateTime.now());
    final key = dayKey(day);
    final dayMonth = dates.dayMonthLong(key);
    if (key == today) return '${l10n.common_today}, $dayMonth';
    if (key == today.subtract(const Duration(days: 1))) {
      return '${l10n.common_yesterday}, $dayMonth';
    }
    if (key == today.add(const Duration(days: 1))) {
      return '${l10n.common_tomorrow}, $dayMonth';
    }
    return dates.fullWeekdayDayMonth(key);
  }
}
