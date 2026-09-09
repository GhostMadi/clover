/** Справочник тегов маркера (EN key → RU), как MarkerTagKey + группы. */

import type { AppServiceKind } from "@/lib/service-accent";

export type MarkerTagGroupKey =
  | "who"
  | "type"
  | "for"
  | "place"
  | "event"
  | "format"
  | "conditions"
  | "admin"
  | "worker";

export type MarkerTagDef = {
  key: string;
  label: string;
  group: MarkerTagGroupKey;
};

export const MARKER_TAG_GROUPS: { key: MarkerTagGroupKey; label: string }[] = [
  { key: "who", label: "Кто" },
  { key: "type", label: "Тип" },
  { key: "for", label: "Для кого" },
  { key: "place", label: "Место" },
  { key: "event", label: "Событие" },
  { key: "format", label: "Формат" },
  { key: "conditions", label: "Условия" },
  { key: "admin", label: "Админ" },
  { key: "worker", label: "Worker" },
];

const SERVICE_POWER_GROUPS = new Set<MarkerTagGroupKey>(["admin", "worker"]);

export function isServicePowerGroup(group: MarkerTagGroupKey): boolean {
  return SERVICE_POWER_GROUPS.has(group);
}

export const MARKER_TAGS: MarkerTagDef[] = [
  { key: "business", label: "Бизнес", group: "who" },
  { key: "individual", label: "Частное лицо", group: "who" },
  { key: "community", label: "Сообщество", group: "who" },
  { key: "brand", label: "Бренд", group: "who" },

  { key: "salon", label: "Салон", group: "type" },
  { key: "barbershop", label: "Барбершоп", group: "type" },
  { key: "music", label: "Музыка", group: "type" },
  { key: "sports", label: "Спорт", group: "type" },
  { key: "food", label: "Еда", group: "type" },
  { key: "tech", label: "Технологии", group: "type" },
  { key: "store", label: "Магазин", group: "type" },

  { key: "kids", label: "Дети", group: "for" },
  { key: "teens", label: "Подростки", group: "for" },
  { key: "adults", label: "Взрослые", group: "for" },
  { key: "seniors", label: "Пожилые", group: "for" },
  { key: "families", label: "Семьи", group: "for" },
  { key: "couples", label: "Пары", group: "for" },
  { key: "students", label: "Студенты", group: "for" },
  { key: "professionals", label: "Профессионалы", group: "for" },
  { key: "menOnly", label: "Только мужчины", group: "for" },
  { key: "womenOnly", label: "Только женщины", group: "for" },

  { key: "restaurant", label: "Ресторан", group: "place" },
  { key: "cafe", label: "Кафе", group: "place" },
  { key: "bar", label: "Бар", group: "place" },
  { key: "cinema", label: "Кино", group: "place" },
  { key: "club", label: "Клуб", group: "place" },
  { key: "shop", label: "Магазин", group: "place" },
  { key: "beauty", label: "Красота", group: "place" },
  { key: "fitness", label: "Фитнес", group: "place" },
  { key: "medical", label: "Медицина", group: "place" },
  { key: "education", label: "Образование", group: "place" },
  { key: "coworking", label: "Коворкинг", group: "place" },
  { key: "hotel", label: "Отель", group: "place" },
  { key: "mall", label: "Торговый центр", group: "place" },

  { key: "party", label: "Вечеринка", group: "event" },
  { key: "networking", label: "Нетворкинг", group: "event" },
  { key: "workshop", label: "Воркшоп", group: "event" },
  { key: "lecture", label: "Лекция", group: "event" },
  { key: "festival", label: "Фестиваль", group: "event" },
  { key: "concert", label: "Концерт", group: "event" },
  { key: "exhibition", label: "Выставка", group: "event" },
  { key: "movieNight", label: "Киновечер", group: "event" },
  { key: "gameNight", label: "Игровой вечер", group: "event" },
  { key: "dating", label: "Знакомства", group: "event" },
  { key: "kidsEvent", label: "Детское событие", group: "event" },
  { key: "sportEvent", label: "Спортивное событие", group: "event" },
  { key: "sale", label: "Распродажа", group: "event" },
  { key: "grandOpening", label: "Открытие", group: "event" },

  { key: "indoor", label: "В помещении", group: "format" },
  { key: "outdoor", label: "На улице", group: "format" },
  { key: "online", label: "Онлайн", group: "format" },
  { key: "active", label: "Активный отдых", group: "format" },
  { key: "chill", label: "Релакс", group: "format" },
  { key: "extreme", label: "Экстрим", group: "format" },
  { key: "creative", label: "Творчество", group: "format" },
  { key: "educational", label: "Обучение", group: "format" },
  { key: "entertainment", label: "Развлечения", group: "format" },

  { key: "free", label: "Бесплатно", group: "conditions" },
  { key: "paid", label: "Платно", group: "conditions" },
  { key: "reservation", label: "По записи", group: "conditions" },
  { key: "limitedSpots", label: "Ограниченное число мест", group: "conditions" },
  { key: "petFriendly", label: "Можно с питомцами", group: "conditions" },
  { key: "eco", label: "Эко", group: "conditions" },
  { key: "18plus", label: "18+", group: "conditions" },
  { key: "night", label: "Ночное", group: "conditions" },
  { key: "newEvent", label: "Новинка", group: "conditions" },
  { key: "popular", label: "Популярное", group: "conditions" },

  { key: "booking", label: "Принимаю запись", group: "admin" },
  { key: "attendance", label: "Веду посещаемость", group: "admin" },
  { key: "resources", label: "Веду ресурсы", group: "admin" },
  { key: "bookingCalendar", label: "Календарь заказов", group: "worker" },
  { key: "attendanceWork", label: "Мои отметки", group: "worker" },
];

const LABEL_BY_KEY = Object.fromEntries(MARKER_TAGS.map((t) => [t.key, t.label]));
const TAG_BY_KEY = Object.fromEntries(MARKER_TAGS.map((t) => [t.key, t]));

export function tagLabelRu(key: string): string {
  return LABEL_BY_KEY[key] ?? key;
}

export function tagByKey(key: string): MarkerTagDef | undefined {
  return TAG_BY_KEY[key];
}

/** Сервисный цвет для силовых тегов (как MarkerTagKey.serviceKind). */
export function tagServiceKind(key: string): AppServiceKind | null {
  const tag = TAG_BY_KEY[key];
  if (!tag || !isServicePowerGroup(tag.group)) return null;
  if (tag.key === "booking" || tag.key === "bookingCalendar") return "booking";
  if (tag.key === "attendance" || tag.key === "attendanceWork") return "attendance";
  if (tag.key === "resources") return "resources";
  return null;
}

export function tagsForFilter(): MarkerTagDef[] {
  return MARKER_TAGS.filter((t) => !isServicePowerGroup(t.group));
}

export function isKnownTagKey(key: string): boolean {
  return MARKER_TAGS.some((t) => t.key === key && !isServicePowerGroup(t.group));
}
