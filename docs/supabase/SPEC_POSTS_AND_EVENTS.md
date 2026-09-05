# Posts & events (Supabase)

**Продукт:** [publications.md](../business/publications.md)  
**Миграции:** см. `MIGRATIONS_INDEX.md` → `posts`, `post_media`, `markers`, enriched RPC.

---

## Модель «Post + extensions»

| Сущность | Роль |
|----------|------|
| `public.posts` | Корень: медиа, текст, реакции, `cluster_id`, **`marker_id`** |
| `public.markers` | Payload ивента (место, период ≤ 24 ч, cover, статус) |
| `posts.marker_id` | FK-gate: `NULL` → обычный пост; uuid → ивент |

Клиент **не** создаёт «голый маркер»: при публикации ивента `PostCreateRepository.publish()` вставляет `markers` → `posts` с `marker_id` → `post_media` → теги/фильтры.

---

## Enriched JSON (один RPC на карточку)

Функции в `20260730180000_post_enriched_json_helpers.sql`:

| Функция | Назначение |
|---------|------------|
| `marker_enriched_json(uuid)` | Маркер + теги; при `NULL` id → `null` без join |
| `post_enriched_root_json(posts)` | Строка поста + `post_media`, `tags`, **`marker`**, `profile_filters` |
| `post_enriched_list_json(posts)` | Как root, **без** `marker` — лента профиля / сетка |
| `get_post_enriched(uuid)` | Один пост для детали / map sheet |
| `list_user_feed_enriched_cursor(jsonb)` | Лента профиля (lightweight list JSON) |
| `list_events_feed_enriched_cursor(jsonb)` | Лента Event / «Все» |

Правило: **не** тянуть marker отдельным REST, если уже есть enriched (теги маркера в `post.marker.tags`).  
Лента профиля: `marker_id` на строке поста для `isEvent`; полный marker — только `get_post_enriched`.

---

## Создание (Flutter)

| Путь | Описание |
|------|----------|
| `PostCreateRepository.publish(PostCreateRequest)` | Единая точка: `eventPeriod == null` → post only; иначе marker + post |
| Storage | `post_media` bucket, path `posts/{post_id}/{media_id}.jpg` |
| Legacy Edge `create_post` | Не используется клиентом (base64 / лимиты); см. комментарий в `supabase/functions/create_post/index.ts` |

`PostCreateRequest.isEvent` ⇔ `eventPeriod != null` (валидация на compose: эмодзи, место с координатами, 1 мин–24 ч).

---

## Архив / удаление

| Действие | Бэк |
|----------|-----|
| Архив обычного поста | `posts.is_archived = true` |
| Архив ивента | `markers.is_archived = true` (пост остаётся привязан) |
| Удаление | RPC `delete_owned_post` + storage cleanup |

Клиент: `PostFeedItem.eventMarkerId` (= `posts.marker_id`) достаточен для archive без загрузки marker payload.

---

## Видимость

- RLS + RPC фильтруют `profiles.account_state <> 'hibernate'`, `content_visible`, `is_archived`, `deleted_at`.
- Карта: `list_markers_map` — маркеры с `post_id is not null`.

---

## Связанные файлы (Flutter)

```
lib/feature/_post_/post/              — read, reactions, archive
lib/feature/_post_/post_create/       — compose + PostCreateRepository (пост и ивент)
lib/feature/_feed_/events_page/       — лента города
lib/feature/_feed_/map_page/          — карта
```
