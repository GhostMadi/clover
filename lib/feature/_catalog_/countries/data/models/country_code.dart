/// Код страны как в `public.countries.code` (нижний регистр, camelCase-имена значений).
enum CountryCode {
  kz('kz', 'Казахстан'),
  ru('ru', 'Россия');

  const CountryCode(this.code, this.labelRu);

  /// Значение колонки `countries.code`.
  final String code;

  /// Подпись для UI (русский).
  final String labelRu;

  static CountryCode? tryParse(String? raw) {
    final c = raw?.trim().toLowerCase();
    if (c == null || c.isEmpty) return null;
    for (final v in CountryCode.values) {
      if (v.code == c) return v;
    }
    return null;
  }
}
