## Markers (events on map)

Миграции **не переносить** из корня `supabase/migrations/` — Supabase учитывает только файлы по timestamp в корне. Эта папка — навигатор по домену **маркеры / события на карте**.

### Идея данных

- **`markers`** — лёгкий объект для карты (быстрая загрузка).
- Контент живёт в **`posts`**. Связь «у этого маркера есть эти посты» — через **`public.marker_posts`** (M2M-таблица: `marker_id`, `post_id`, `sort_order`, `is_primary`).
- **`posts.marker_id`** — удобная колонка на посте: «этот пост относится к маркеру X». У **многих** постов может быть **один и тот же** `marker_id` (один маркер — много постов).
- **`markers.post_id`** — **денормализация**: «главный» пост для превью карты / обложки (обычно `is_primary = true` в `marker_posts`). Обновляется триггерами, клиенту карты по-прежнему достаточно лёгкого поля `post_id` в выдаче RPC.

Маркер считаем **видимым на карте**, если есть **хотя бы одна** строка в `marker_posts` (и выполняются фильтры `is_archived`, время, гео и т.д.).

Теги — справочник **`marker_tags`** + m2m **`marker_tag_links`**.

### Время и жизненный цикл

Поля:

- `event_time` — начало события
- `duration` — длительность (ограничение: `<= 24 hours`)
- `end_time` — вычисляется как `event_time + duration` (поддерживается триггером)

Отображение на карте (по умолчанию): **только upcoming + active** (через `p_at_time` в RPC можно подставить любую дату).

Статус рассчитывается «эффективно» по времени:

- `cancelled` → cancelled
- `at_time < event_time` → upcoming
- `event_time <= at_time <= end_time` → active
- иначе → finished

### Миграции по порядку внедрения

| Файл | Назначение |
|------|------------|
| `../20260425160000_markers_core.sql` | PostGIS extension; enum `marker_status`; таблицы `markers`, `marker_tags`, `marker_tag_links`; базовая версия домена; seed словаря тегов; RPC `list_markers_map`. |
| `../20260425171000_markers_bind_post_id.sql` | Связь маркер ↔ пост через `markers.post_id`; карта только при наличии поста; обновление `list_markers_map` и политики SELECT. |
| `../20260427100000_posts_marker_id_bidirectional.sql` | Колонка `posts.marker_id` для запросов с поста. |
| `../20260628120000_marker_posts_many_per_marker.sql` | Таблица **`marker_posts`**: один маркер — много постов; снятие unique на `posts.marker_id`; триггеры синхронизации `markers.post_id`; обновление `list_markers_map`; RPC **`list_marker_posts`**. |
| `../20260628121500_list_markers_map_multi_post_preview.sql` | **`list_markers_map`**: поля **`post_count`**, **`preview_image_urls`** (до 4), карта показывает и **пустые** маркеры (без `marker_posts`). |

### Гео и сортировка

- Гео-фильтр: `ST_DWithin(location, user_location, radius_m)`
- Сортировка: `distance ASC`, затем `event_time ASC`
- Индекс: `GIST(location)` + btree по `event_time/end_time/status`

### RPC (контракт)

#### `public.list_markers_map`

Назначение: быстро получить маркеры для карты в радиусе с фильтрами.

Параметры (основные):

- `p_lat`, `p_lng` — позиция пользователя
- `p_radius_m` — радиус в метрах
- `p_at_time` — «текущее» время для расчёта статуса (по умолчанию now)
- `p_emoji` — фильтр по `text_emoji` (опционально)
- `p_tag_keys` — фильтр по тегам (опционально, массив ключей из `marker_tags.key`)

Условие «маркер с контентом»: **`exists (select 1 from marker_posts …)`** (не массив в JSON).

Возвращает (лёгкая модель, в т.ч. денормализованный `post_id` для превью).

#### `public.list_marker_posts`

Список постов маркера в порядке отображения (`is_primary`, `sort_order`, время).

### Связь с приложением (Flutter)

- Теги и маркеры: `lib/feature/marker_tag/` (репозиторий + cubit).
- UI словарь ключей/переводов тегов: `lib/feature/marker_tag/domain/marker_tag_dictionary.dart`.
- Дальше на клиенте: при создании поста с `marker_id` строка в `marker_posts` создаётся **триггером** на `posts`; для кастомного порядка / смены «главного» поста можно писать в `marker_posts` (владелец маркера по RLS).
