import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/locale/app_date_format.dart';
import 'package:clover/core/locale/app_locale_cubit.dart';
import 'package:clover/l10n/app_localizations.dart';

abstract final class MessageChatTimeFormatting {
  static String format(DateTime dateTime) {
    final local = dateTime.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDay = DateTime(local.year, local.month, local.day);
    final diffDays = today.difference(messageDay).inDays;
    final dates = AppDateFormat.current();
    final l10n = lookupAppLocalizations(sl<AppLocaleCubit>().state.locale);

    if (diffDays == 0) {
      final hour = local.hour.toString().padLeft(2, '0');
      final minute = local.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    }
    if (diffDays == 1) return l10n.common_yesterday;
    if (diffDays < 7) {
      return dates.shortWeekday(local);
    }

    return dates.dayMonthNumeric(local);
  }
}
