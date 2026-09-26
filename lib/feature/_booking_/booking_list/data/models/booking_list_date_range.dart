import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/locale/app_date_format.dart';
import 'package:clover/core/locale/app_locale_cubit.dart';
import 'package:clover/l10n/app_localizations.dart';

class BookingListDateRange {
  const BookingListDateRange({required this.start, required this.end});

  final DateTime start;
  final DateTime end;

  static DateTime _day(DateTime value) => DateTime(value.year, value.month, value.day);

  static DateTime _today() => _day(DateTime.now());

  /// Понедельник текущей недели (ISO).
  static DateTime _mondayOf(DateTime day) => day.subtract(Duration(days: day.weekday - 1));

  factory BookingListDateRange.today() {
    final day = _today();
    return BookingListDateRange(start: day, end: day);
  }

  factory BookingListDateRange.tomorrow() {
    final day = _today().add(const Duration(days: 1));
    return BookingListDateRange(start: day, end: day);
  }

  /// С сегодня до воскресенья текущей недели.
  factory BookingListDateRange.thisWeek() {
    final today = _today();
    final sunday = _mondayOf(today).add(const Duration(days: 6));
    return BookingListDateRange(start: today, end: sunday);
  }

  /// Следующая полная неделя (пн–вс).
  factory BookingListDateRange.nextWeek() {
    final today = _today();
    final nextMonday = _mondayOf(today).add(const Duration(days: 7));
    final nextSunday = nextMonday.add(const Duration(days: 6));
    return BookingListDateRange(start: nextMonday, end: nextSunday);
  }

  /// С сегодня до конца текущего месяца.
  factory BookingListDateRange.thisMonth() {
    final today = _today();
    final end = DateTime(today.year, today.month + 1, 0);
    return BookingListDateRange(start: today, end: end);
  }

  /// Весь следующий календарный месяц.
  factory BookingListDateRange.nextMonth() {
    final today = _today();
    final start = DateTime(today.year, today.month + 1, 1);
    final end = DateTime(today.year, today.month + 2, 0);
    return BookingListDateRange(start: start, end: end);
  }

  /// Прошлые и предстоящие записи клиента (≈ месяц назад — 2 месяца вперёд).
  factory BookingListDateRange.recentAndUpcoming() {
    final today = _today();
    return BookingListDateRange(
      start: today.subtract(const Duration(days: 30)),
      end: today.add(const Duration(days: 60)),
    );
  }

  /// Host inbox: забытые/история + ближайшие записи.
  factory BookingListDateRange.hostInbox() {
    final today = _today();
    return BookingListDateRange(
      start: today.subtract(const Duration(days: 45)),
      end: today.add(const Duration(days: 60)),
    );
  }

  bool sameDayRange(BookingListDateRange other) {
    return _day(start) == _day(other.start) && _day(end) == _day(other.end);
  }

  bool contains(DateTime dateTime) {
    final day = _day(dateTime);
    final from = _day(start);
    final to = _day(end);
    return !day.isBefore(from) && !day.isAfter(to);
  }

  String get label {
    final dates = AppDateFormat.current();
    final l10n = lookupAppLocalizations(sl<AppLocaleCubit>().state.locale);

    final from = _day(start);
    final to = _day(end);
    final today = _today();

    if (sameDayRange(BookingListDateRange.today())) return l10n.common_today;
    if (sameDayRange(BookingListDateRange.tomorrow())) return l10n.common_tomorrow;
    if (sameDayRange(BookingListDateRange.thisWeek())) return l10n.booking_range_this_week;
    if (sameDayRange(BookingListDateRange.nextWeek())) return l10n.booking_range_next_week;
    if (sameDayRange(BookingListDateRange.thisMonth())) return l10n.booking_range_this_month;
    if (sameDayRange(BookingListDateRange.nextMonth())) return l10n.booking_range_next_month;
    if (sameDayRange(BookingListDateRange.hostInbox())) return l10n.booking_range_all;
    if (sameDayRange(BookingListDateRange.recentAndUpcoming())) return l10n.booking_range_recent;

    if (from == to) {
      if (from == today) return l10n.common_today;
      return dates.dayMonth(from);
    }

    final startLabel = dates.dayMonth(from);
    final endLabel = dates.dayMonth(to);
    if (from.year == to.year) {
      return '$startLabel — $endLabel ${from.year}';
    }
    return '$startLabel ${from.year} — $endLabel ${to.year}';
  }
}
