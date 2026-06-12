import 'package:clover/feature/profile_page/data/model/profile_new_model.dart';

/// Форматирование данных профиля для UI (без виджетов — легко тестировать и переиспользовать).
abstract final class ProfilePageFormatting {
  /// Никнейм для заголовка/подписи; иначе имя или запасной текст.
  static String displayHandle(ProfileNewModel p) {
    final u = p.username?.trim();
    if (u != null && u.isNotEmpty) return u;
    final n = p.fullName?.trim();
    if (n != null && n.isNotEmpty) return n;
    return 'Профиль';
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
  static String locationLine(ProfileNewModel p) {
    final cityLine = p.cityLabel?.trim();
    final country = p.countryCode;
    final hasCity = cityLine != null && cityLine.isNotEmpty;
    final countryLine = country?.labelRu.trim();

    if (hasCity && countryLine != null && countryLine.isNotEmpty) {
      return '$countryLine,$cityLine';
    }
    if (hasCity) return cityLine;
    if (countryLine != null && countryLine.isNotEmpty) return countryLine;
    return '';
  }
}
