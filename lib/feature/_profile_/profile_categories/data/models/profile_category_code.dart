/// Код категории как в `public.profile_categories.code` (slug, camelCase-имена).
enum ProfileCategoryCode {
  beauty('beauty', 'Красота'),
  music('music', 'Музыка'),
  sports('sports', 'Спорт'),
  food('food', 'Еда'),
  tech('tech', 'Технологии'),
  store('store', 'Магазин'),
  barbershop('barbershop', 'Барбершоп'),
  salon('salon', 'Салон'),
  restaurant('restaurant', 'Ресторан');

  const ProfileCategoryCode(this.value, this.labelRu);

  final String value;
  final String labelRu;

  static ProfileCategoryCode? tryParse(String? raw) {
    final c = raw?.trim().toLowerCase();
    if (c == null || c.isEmpty) return null;
    for (final v in ProfileCategoryCode.values) {
      if (v.value == c) return v;
    }
    return null;
  }
}
