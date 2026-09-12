# Locations (Ресурсы → Местоположения)

**Продукт:** [docs/business/locations.md](../business/locations.md)  
**Таблица:** `public.locations` (миграция `20260613120000_locations.sql`)  
**Тег UI:** `resources` в `marker_tags` — гейт хаба, не RLS таблицы.

## Контракт адресов

| Колонка | Смысл |
|---------|--------|
| `address_primary` | NOT NULL. Латиница, если есть; иначе кириллица (fallback). |
| `address_cyrillic` | Кириллица (обязательна в UI создания). |

Клиенты: Flutter `LocationRepository` + web `createManagedLocation` / update — **один** маппинг.  
Не писать кириллицу в `address_primary`, а латиницу в `address_cyrillic`.

## RLS

Только владелец (`owner_id = auth.uid()`). Страна/город — пара ключей каталога или оба null.

## INDEX

См. `MIGRATIONS_INDEX.md` → Locations / Resources.
