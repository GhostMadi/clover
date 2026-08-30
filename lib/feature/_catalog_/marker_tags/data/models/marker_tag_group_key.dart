/// Группа тега маркера как в `public.marker_tags.group_key`.
enum MarkerTagGroupKey {
  who('who', 'Кто', 0),
  forAudience('for', 'Для кого', 1),
  place('place', 'Место', 2),
  event('event', 'Событие', 3),
  format('format', 'Формат', 4),
  conditions('conditions', 'Условия', 5),
  account('account', 'Аккаунт', 6);

  const MarkerTagGroupKey(this.key, this.labelRu, this.sortOrder);

  /// Значение колонки `marker_tags.group_key`.
  final String key;

  /// Подпись секции в UI.
  final String labelRu;

  /// Порядок групп в списке выбора.
  final int sortOrder;

  static MarkerTagGroupKey? tryParse(String? raw) {
    final normalized = raw?.trim();
    if (normalized == null || normalized.isEmpty) return null;
    for (final value in MarkerTagGroupKey.values) {
      if (value.key == normalized) return value;
    }
    return null;
  }

  static int compare(MarkerTagGroupKey? a, MarkerTagGroupKey? b) {
    if (a == null && b == null) return 0;
    if (a == null) return 1;
    if (b == null) return -1;
    return a.sortOrder.compareTo(b.sortOrder);
  }
}
