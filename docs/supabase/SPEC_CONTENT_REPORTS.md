# SPEC — Content reports (UGC safety)

**Продукт:** [ugc-safety.md](../business/ugc-safety.md) · [blocks.md](../business/blocks.md)  
**Миграция:** `20260924130309_content_reports_and_ugc_feed_filter.sql`

---

## Таблица `public.content_reports`

| Колонка | Тип | Смысл |
|---------|-----|--------|
| `id` | uuid PK | |
| `reporter_id` | uuid → profiles | Кто пожаловался / кто заблокировал |
| `target_user_id` | uuid → profiles | На кого |
| `target_post_id` | uuid → posts nullable | Пост (если жалоба с поста) |
| `reason_code` | text | EN: `objectionable_content` \| `abusive_user` \| `spam` \| `harassment` \| `other` |
| `source` | text | `report` \| `block` |
| `note` | text nullable | Свободный текст (короткий) |
| `status` | text | `open` \| `resolved` \| `dismissed` |
| `created_at` | timestamptz | |

Constraints: не self-report; `reason_code` / `source` / `status` — check на EN-ключи.  
Index: `(status, created_at desc)` для очереди модерации.

### RLS

- `authenticated` **select** только своих строк (`reporter_id = auth.uid()`)  
- **insert/update/delete** у `authenticated` — **revoke**; только SECURITY DEFINER RPC  
- service_role — полный доступ для модерации

---

## RPC

### `report_content(p_target_user uuid, p_reason text, p_post_id uuid default null, p_note text default null)`

- Auth required  
- Нельзя на себя  
- `source = 'report'`  
- Идемпотентно: если уже есть `open` от того же reporter на тот же `(target_user, post)` — no-op  
- Returns void

### `block_user(p_target uuid, p_reason text default 'abusive_user', p_post_id uuid default null, p_note text default null)`

- Как раньше: insert `profile_blocks`, unfollow both ways  
- **Плюс:** insert `content_reports` (`source='block'`, reason/post/note) — уведомление разработчику  
- Если уже есть **open** жалоба на того же target/post — не вставляем вторую (иначе unique → 409); помечаем существующую  
- Старый вызов только с `p_target` остаётся валидным

### Feed / map filter

В `list_events_feed_enriched_cursor`, `list_markers_map`, `list_markers_map_clusters`, `count_markers_map`:

- если `auth.uid()` задан — не отдавать посты / маркеры авторов, с которыми есть блок (симметрия через `profile_blocks`)

Helper: `viewer_is_blocked_with(p_other uuid) returns boolean`.

---

## Клиенты

| Клиент | Контракт |
|--------|----------|
| Mobile | `ContentReportRepository.report…` · `SocialGraphRepository.blockUser` (+ optional reason) |
| Web | те же RPC |

Подписи причин — только на клиенте (`ContentReportReason.labelRu`).
