import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/locale/app_locale.dart';
import 'package:clover/core/locale/app_locale_cubit.dart';
import 'package:intl/intl.dart';

/// Locale-aware date labels via [intl] (not ARB month/weekday keys).
///
/// Locale follows app UI (`ru` / `en` / `kk`). Week grids use ISO Monday-first.
final class AppDateFormat {
  AppDateFormat(this.locale);

  factory AppDateFormat.fromAppLocale(AppLocale locale) => AppDateFormat(locale.languageCode);

  /// Current UI locale from [AppLocaleCubit] (data / form helpers without [BuildContext]).
  factory AppDateFormat.current() =>
      AppDateFormat(sl<AppLocaleCubit>().state.languageCode);

  /// BCP 47 / language code, e.g. `ru`, `en`, `kk`.
  final String locale;

  DateFormat _fmt(String pattern) => DateFormat(pattern, locale);

  /// `Январь 2026` / `January 2026`.
  String monthYear(DateTime date) => _fmt('yMMMM').format(date);

  /// Full month name for [month] 1…12.
  String monthName(int month) {
    assert(month >= 1 && month <= 12);
    return _fmt('MMMM').format(DateTime(2020, month));
  }

  /// Twelve full month names (picker drums).
  List<String> monthNames() => [for (var m = 1; m <= 12; m++) monthName(m)];

  /// Abbreviated month: `янв` / `Jan`.
  String shortMonth(DateTime date) => _fmt('MMM').format(date);

  /// Short weekday for a concrete date: `пн` / `Mon`.
  String shortWeekday(DateTime date) => _fmt('E').format(date);

  /// Full weekday: `понедельник` / `Monday`.
  String fullWeekday(DateTime date) => _fmt('EEEE').format(date);

  /// `26 сент.` / `26 Sep` (locale punctuation).
  String dayMonth(DateTime date) => _fmt('d MMM').format(date);

  /// `26 сентября` style via medium date without year when possible.
  String dayMonthLong(DateTime date) => _fmt('d MMMM').format(date);

  /// Journal style: `26 сент., пн`.
  String dayMonthWeekday(DateTime date) => '${dayMonth(date)}, ${shortWeekday(date)}';

  /// `понедельник, 26 сентября`.
  String fullWeekdayDayMonth(DateTime date) => '${fullWeekday(date)}, ${dayMonthLong(date)}';

  /// ISO Monday→Sunday short labels for calendar headers.
  List<String> weekdayShortLabels() {
    // 2024-01-01 was Monday.
    return [
      for (var i = 0; i < 7; i++) shortWeekday(DateTime(2024, 1, 1 + i)),
    ];
  }

  /// `26.09` numeric short (locale-neutral digits).
  String dayMonthNumeric(DateTime date) {
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    return '$dd.$mm';
  }
}
