import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/locale/app_locale_cubit.dart';
import 'package:clover/l10n/app_localizations.dart';

abstract final class CommentTimeFormat {
  CommentTimeFormat._();

  static String format(DateTime createdAt) {
    final l10n = lookupAppLocalizations(sl<AppLocaleCubit>().state.locale);
    final local = createdAt.toLocal();
    final diff = DateTime.now().difference(local);

    if (diff.inMinutes < 1) return l10n.post_now;
    if (diff.inHours < 1) return l10n.post_relative_minutes(diff.inMinutes);
    if (diff.inDays < 1) return l10n.post_relative_hours(diff.inHours);
    if (diff.inDays < 7) return l10n.post_relative_days(diff.inDays);
    if (local.year == DateTime.now().year) {
      return '${local.day.toString().padLeft(2, '0')}.${local.month.toString().padLeft(2, '0')}';
    }
    return '${local.day.toString().padLeft(2, '0')}.${local.month.toString().padLeft(2, '0')}.${local.year}';
  }
}
