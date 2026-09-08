/// Группа тега маркера как в `public.marker_tags.group_key`.
enum MarkerTagGroupKey {
  who('who', 'Кто', 0),
  type('type', 'Тип', 1),
  forAudience('for', 'Для кого', 2),
  place('place', 'Место', 3),
  event('event', 'Событие', 4),
  format('format', 'Формат', 5),
  conditions('conditions', 'Условия', 6),

  /// Супер-сила хозяина точки: мажорные сервисы (запись, …).
  admin('admin', 'Админ', 7),

  /// Супер-сила исполнителя: доп. функции («мне дают», …).
  worker('worker', 'Worker', 8);

  const MarkerTagGroupKey(this.key, this.labelRu, this.sortOrder);

  /// Значение колонки `marker_tags.group_key`.
  final String key;

  /// Подпись секции в UI.
  final String labelRu;

  /// Порядок групп в списке выбора.
  final int sortOrder;

  /// Группы сил сервисов (не фильтры ленты / маркеров).
  bool get isServicePower => this == admin || this == worker;

  static const Set<MarkerTagGroupKey> servicePowerGroups = {
    MarkerTagGroupKey.admin,
    MarkerTagGroupKey.worker,
  };

  static MarkerTagGroupKey? tryParse(String? raw) {
    final normalized = raw?.trim();
    if (normalized == null || normalized.isEmpty) return null;
    // Legacy: старый group_key `account` → трактуем как admin (мажорные силы).
    if (normalized == 'account') return MarkerTagGroupKey.admin;
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
