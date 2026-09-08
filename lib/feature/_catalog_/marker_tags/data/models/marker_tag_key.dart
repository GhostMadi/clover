import 'package:clover/core/resources/app_service_accent.dart';
import 'package:clover/feature/_catalog_/marker_tags/data/models/marker_tag_group_key.dart';

/// Ключ тега маркера как в `public.marker_tags.key`.
enum MarkerTagKey {
  // who
  business('business', 'Бизнес', MarkerTagGroupKey.who),
  individual('individual', 'Частное лицо', MarkerTagGroupKey.who),
  community('community', 'Сообщество', MarkerTagGroupKey.who),
  brand('brand', 'Бренд', MarkerTagGroupKey.who),

  // type (ex profile categories)
  salon('salon', 'Салон', MarkerTagGroupKey.type),
  barbershop('barbershop', 'Барбершоп', MarkerTagGroupKey.type),
  music('music', 'Музыка', MarkerTagGroupKey.type),
  sports('sports', 'Спорт', MarkerTagGroupKey.type),
  food('food', 'Еда', MarkerTagGroupKey.type),
  tech('tech', 'Технологии', MarkerTagGroupKey.type),
  store('store', 'Магазин', MarkerTagGroupKey.type),

  // for
  kids('kids', 'Дети', MarkerTagGroupKey.forAudience),
  teens('teens', 'Подростки', MarkerTagGroupKey.forAudience),
  adults('adults', 'Взрослые', MarkerTagGroupKey.forAudience),
  seniors('seniors', 'Пожилые', MarkerTagGroupKey.forAudience),
  families('families', 'Семьи', MarkerTagGroupKey.forAudience),
  couples('couples', 'Пары', MarkerTagGroupKey.forAudience),
  students('students', 'Студенты', MarkerTagGroupKey.forAudience),
  professionals('professionals', 'Профессионалы', MarkerTagGroupKey.forAudience),
  menOnly('menOnly', 'Только мужчины', MarkerTagGroupKey.forAudience),
  womenOnly('womenOnly', 'Только женщины', MarkerTagGroupKey.forAudience),

  // place
  restaurant('restaurant', 'Ресторан', MarkerTagGroupKey.place),
  cafe('cafe', 'Кафе', MarkerTagGroupKey.place),
  bar('bar', 'Бар', MarkerTagGroupKey.place),
  cinema('cinema', 'Кино', MarkerTagGroupKey.place),
  club('club', 'Клуб', MarkerTagGroupKey.place),
  shop('shop', 'Магазин', MarkerTagGroupKey.place),
  beauty('beauty', 'Красота', MarkerTagGroupKey.place),
  fitness('fitness', 'Фитнес', MarkerTagGroupKey.place),
  medical('medical', 'Медицина', MarkerTagGroupKey.place),
  education('education', 'Образование', MarkerTagGroupKey.place),
  coworking('coworking', 'Коворкинг', MarkerTagGroupKey.place),
  hotel('hotel', 'Отель', MarkerTagGroupKey.place),
  mall('mall', 'Торговый центр', MarkerTagGroupKey.place),

  // event
  party('party', 'Вечеринка', MarkerTagGroupKey.event),
  networking('networking', 'Нетворкинг', MarkerTagGroupKey.event),
  workshop('workshop', 'Воркшоп', MarkerTagGroupKey.event),
  lecture('lecture', 'Лекция', MarkerTagGroupKey.event),
  festival('festival', 'Фестиваль', MarkerTagGroupKey.event),
  concert('concert', 'Концерт', MarkerTagGroupKey.event),
  exhibition('exhibition', 'Выставка', MarkerTagGroupKey.event),
  movieNight('movieNight', 'Киновечер', MarkerTagGroupKey.event),
  gameNight('gameNight', 'Игровой вечер', MarkerTagGroupKey.event),
  dating('dating', 'Знакомства', MarkerTagGroupKey.event),
  kidsEvent('kidsEvent', 'Детское событие', MarkerTagGroupKey.event),
  sportEvent('sportEvent', 'Спортивное событие', MarkerTagGroupKey.event),
  sale('sale', 'Распродажа', MarkerTagGroupKey.event),
  grandOpening('grandOpening', 'Открытие', MarkerTagGroupKey.event),

  // format
  indoor('indoor', 'В помещении', MarkerTagGroupKey.format),
  outdoor('outdoor', 'На улице', MarkerTagGroupKey.format),
  online('online', 'Онлайн', MarkerTagGroupKey.format),
  active('active', 'Активный отдых', MarkerTagGroupKey.format),
  chill('chill', 'Релакс', MarkerTagGroupKey.format),
  extreme('extreme', 'Экстрим', MarkerTagGroupKey.format),
  creative('creative', 'Творчество', MarkerTagGroupKey.format),
  educational('educational', 'Обучение', MarkerTagGroupKey.format),
  entertainment('entertainment', 'Развлечения', MarkerTagGroupKey.format),

  // conditions
  free('free', 'Бесплатно', MarkerTagGroupKey.conditions),
  paid('paid', 'Платно', MarkerTagGroupKey.conditions),
  reservation('reservation', 'По записи', MarkerTagGroupKey.conditions),
  limitedSpots('limitedSpots', 'Ограниченное число мест', MarkerTagGroupKey.conditions),
  petFriendly('petFriendly', 'Можно с питомцами', MarkerTagGroupKey.conditions),
  eco('eco', 'Эко', MarkerTagGroupKey.conditions),
  plus18('18plus', '18+', MarkerTagGroupKey.conditions),
  night('night', 'Ночное', MarkerTagGroupKey.conditions),
  newEvent('newEvent', 'Новинка', MarkerTagGroupKey.conditions),
  popular('popular', 'Популярное', MarkerTagGroupKey.conditions),

  // admin — мажорные силы хозяина точки
  booking('booking', 'Принимаю запись', MarkerTagGroupKey.admin),

  // worker — доп. функции исполнителя
  bookingCalendar('bookingCalendar', 'Календарь заказов', MarkerTagGroupKey.worker);

  const MarkerTagKey(this.key, this.labelRu, this.groupKey);

  /// Значение колонки `marker_tags.key`.
  final String key;

  /// Подпись для UI (русский).
  final String labelRu;

  /// Группа тега (денормализация из `group_key` на сервере).
  final MarkerTagGroupKey groupKey;

  static MarkerTagKey? tryParse(String? raw) {
    final normalized = raw?.trim();
    if (normalized == null || normalized.isEmpty) return null;
    for (final value in MarkerTagKey.values) {
      if (value.key == normalized) return value;
    }
    return null;
  }

  /// Тег силы «админ» (мажорный сервис хозяина).
  bool get isAdminPower => groupKey == MarkerTagGroupKey.admin;

  /// Тег силы «worker» (доп. функции исполнителя).
  bool get isWorkerPower => groupKey == MarkerTagGroupKey.worker;

  bool get isServicePower => groupKey.isServicePower;

  /// Продуктовый сервис, к которому относится сила (цвет чипа / акцента).
  ///
  /// Витринные теги (`who` / `type` / …) → `null` (нейтральный бренд).
  AppServiceKind? get serviceKind => switch (this) {
    MarkerTagKey.booking || MarkerTagKey.bookingCalendar => AppServiceKind.booking,
    _ => null,
  };
}
