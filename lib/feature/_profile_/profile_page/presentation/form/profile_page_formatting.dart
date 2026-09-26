import 'package:clover/feature/_profile_/profile_page/data/model/profile_new_model.dart';
import 'package:clover/l10n/app_localizations.dart';
import 'package:clover/feature/_catalog_/shared/catalog_l10n.dart';

/// Форматирование данных профиля для UI (без виджетов — легко тестировать и переиспользовать).
abstract final class ProfilePageFormatting {
  /// Никнейм для заголовка/подписи; иначе имя или запасной текст.
  static String displayHandle(ProfileNewModel p, {AppLocalizations? l10n}) {
    final u = p.username?.trim();
    if (u != null && u.isNotEmpty) return u;
    final n = p.fullName?.trim();
    if (n != null && n.isNotEmpty) return n;
    return l10n?.profile_fallback_name ?? 'Profile';
  }

  static String statString(int n) {
    if (n >= 1000000) {
      final v = (n / 1000000).toStringAsFixed(1);
      return v.endsWith('.0') ? '${v.substring(0, v.length - 2)}M' : '${v}M';
    }
    if (n >= 1000) {
      final v = (n / 1000).toStringAsFixed(1);
      return v.endsWith('.0') ? '${v.substring(0, v.length - 2)}k' : '${v}k';
    }
    return '$n';
  }

  /// Город и страна: при наличии города — «страна,город», иначе только страна или город.
  static String locationLine(ProfileNewModel p, {AppLocalizations? l10n}) {
    final cityLine = p.cityLabel?.trim();
    final country = p.countryCode;
    final hasCity = cityLine != null && cityLine.isNotEmpty;
    final countryLine = country == null
        ? null
        : (l10n != null ? country.label(l10n) : country.labelRu).trim();

    if (hasCity && countryLine != null && countryLine.isNotEmpty) {
      return '$countryLine, $cityLine';
    }
    if (hasCity) return cityLine;
    if (countryLine != null && countryLine.isNotEmpty) return countryLine;
    return '';
  }
}
