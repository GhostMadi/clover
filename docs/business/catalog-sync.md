# Справочники на клиенте (enum-only)

**Статус:** актуально  
**Связано:** [localization-dictionaries.md](localization-dictionaries.md), [profile-data.md](profile-data.md)

---

## Идея

Страны, города и теги на телефоне — **enum + catalog в коде**, как `CountryCode` / `CityCode` / `MarkerTagKey`.

- Селекторы берут списки из `CountriesCatalog`, `CitiesCatalog`, `MarkerTagsCatalog`.
- Подписи — на фронте (`labelRu` / l10n), не с бэка.
- В Supabase уходит **ключ** (`country_code`, `city_code`, `marker_tags.key`).

Отдельная синхронизация справочников на клиенте **не используется**.

---

## Что на бэке

| Таблица | Роль |
|---------|------|
| `countries` | FK / check для `profiles.country_code` |
| `cities` | FK / check для `profiles.city_code` |
| `marker_tags` | UUID + `key` + `group_key`; связи через `*_tag_links` |

Клиент читает профиль из **`profiles`**, без отдельной таблицы версий справочников.

---

## Запись тегов

UI работает с **ключами** enum. При сохранении профиля / маркера / поста репозиторий один раз резолвит `key → UUID` в `marker_tags` и пишет в `profile_tag_links` / `marker_tag_links` / `post_tag_links`.

---

## Новый пункт справочника

1. Ключ в миграции Supabase (`marker_tags`, `cities`, …).
2. Значение в enum + catalog на фронте.
3. Подпись в enum / l10n.

Без дублирования enum в соседних фичах — общий каталог в `feature/_catalog_/`.
