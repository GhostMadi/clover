## Supabase migrations index

Важно: Supabase применяет миграции **только** из корня `supabase/migrations/` и по имени файла (timestamp).  
Поэтому `.sql` файлы **не переносим** в подпапки. Подпапки ниже — только для навигации.

### Clusters (1 основная миграция)
- `20260402120000_clusters.sql`
  - **tables**: `public.clusters`
  - **triggers**: `clusters_set_updated_at`, `clusters_sync_profile_cluster_count` (поддержка `profiles.cluster_count`)
  - **RLS**: policies для select/insert/update/delete
  - **storage**: bucket `cluster_covers` + policies (cover_url)

### Posts (3 миграции)

**Spec (контракт enriched + create):** [SPEC_POSTS_AND_EVENTS.md](SPEC_POSTS_AND_EVENTS.md)

- `20260402140000_posts_post_media_engagement.sql`
  - **types**: `public.media_type`
  - **tables**: `public.posts`, `public.post_media`, `public.comments`, `public.post_likes`, `public.comment_likes`, `public.post_saves`
  - **triggers**: счётчики `likes_count/comments_count/saves_count`, `clusters.posts_count`, `posts.updated_at`
  - **indexes**: global feed / cluster feed / user feed + дерево комментариев
  - **RLS** + grants

- `20260402150000_post_view_events.sql`
  - **tables**: `public.post_view_events`
  - **batch aggregation**: `public.flush_post_view_events_batch()` (service_role/cron)
  - **RLS**: только insert (authenticated) по видимому посту

- `20260407193000_posts_storage_views_sends.sql`
  - **storage**: bucket `post_media` + policies (path: `posts/{post_id}/{media_id}.*`)
  - **tables**: `public.post_send_events`
  - **triggers**: `posts.sends_count`

- `20260830140000_post_list_enriched_light.sql`
  - **functions**: `post_enriched_list_json` (post + media + tags + filters, **без** marker subtree)
  - **RPC**: `list_user_feed_enriched_cursor` → lightweight JSON для сетки профиля; деталь — `get_post_enriched`

- `20260830150000_fix_category_code_trigger_orphans.sql`
  - **fix**: дроп триггеров/функций с `category_code` после unify tags (INSERT posts 42703)

### Post media (video posters)
- `20260418120001_post_media_poster_url.sql`
  - **post_media**: `poster_url` (JPEG poster для видео плиток/превью)

### Markers (events on map)
- `20260425160000_markers_core.sql`
  - **types**: `public.marker_status`
  - **tables**: `public.markers`, `public.marker_tags`, `public.marker_tag_links`
  - **posts**: ранняя версия связывала через `public.posts.marker_id` (см. следующую миграцию)
  - **time**: `duration <= 24h`, `end_time = event_time + duration` (trigger)
  - **geo**: PostGIS (`location geography(Point,4326)`, `ST_DWithin`, distance sort)
  - **RPC**: `public.list_markers_map(...)` (фильтры emoji/tags + сортировка distance→event_time)

- `20260425171000_markers_bind_post_id.sql`
  - **markers**: `public.markers.post_id` (опциональная связь маркера с постом)
  - **posts**: удаляет `public.posts.marker_id` (переворот связи)
  - **map visibility**: маркер показываем только если `post_id is not null`
  - **RPC**: обновляет `public.list_markers_map(...)` под новый контракт

- `20260425172000_markers_fix_insert_rls.sql`
  - **RLS/grants**: идемпотентно восстанавливает `markers_insert_own/update_own/delete_own` + `GRANT` для `authenticated` (фикс 403 на insert)

- `20260407201000_hot_feed_materialized_view.sql`
  - **materialized view**: `public.hot_posts_24h` (hot feed last 24h)
  - **refresh**: `public.refresh_hot_posts_24h()` + best-effort `pg_cron` schedule (every 5 min)

- `20260412100000_comments_contract_and_root_index.sql`
  - **comments**: частичный индекс `comments_post_root_created_desc_idx` под список корневых комментариев поста (как в приложении)
  - **comment on**: контракт колонок и embed `profiles!comments_user_id_fkey` для PostgREST

### Profile feed filters
- `20260718120000_profile_filters.sql`
  - **column**: `profiles.has_filters` (denormalized gate for filter button)
  - **tables**: `profile_filter_categories`, `profile_filter_values`
  - **trigger**: sync `has_filters` on category insert/delete
  - **RPC**: `list_profile_filter_categories`, `upsert_profile_filter_category`, `delete_profile_filter_category`
  - Навигатор: `migrations/_filters/README.md`

### Profiles / reference data
- `20260329120000_reference_countries_cities_categories.sql` (справочники)
- `20260329140000_profiles_username_change_limit.sql`
- `20260330120000_profile_storage_avatars_backgrounds.sql`
- `20260416100000_profiles_post_count.sql` — `profiles.post_count`, триггеры на `posts`

### Состояние аккаунта (сон / видимость) — **актуальный бэкенд**

Клиент вызывает только **`public.hibernate_account()`** (и при необходимости **`wake_up_if_needed()`**).  
Сброс контента (удаление постов/медиа) **не используется**.

| Файл | Назначение |
|------|------------|
| `20260416112425_account_state_reset_hibernate.sql` | Колонки `profiles`: `account_state`, `content_visible`, `reset_at`, `last_reset_at`, `last_hibernate_at`; soft-delete полей у `clusters`; RLS для скрытия «спящих»; RPC **`hibernate_account`**, **`wake_up_if_needed`**, первая версия **`reset_account`** (исторически — сброс контента). |
| `20260416140000_account_rpc_set_row_security_off.sql` | `SET row_security TO off` на эти RPC (definer + RLS). |
| `20260416150000_reset_account_storage_best_effort.sql` | Итерация `reset_account`: storage try/catch. |
| `20260417100000_reset_account_hard_delete_content.sql` | Итерация `reset_account`: hard-delete строк. |
| `20260418130000_reset_account_storage_posts_clusters.sql` | Итерация `reset_account`: очистка префиксов в Storage. |
| **`20260419000000_disable_reset_account_content_wipe.sql`** | **Финал:** `reset_account()` только `raise exception`; **`revoke execute` у `authenticated`**. Полное удаление контента с клиента отключено. |

Ремонт таблицы кластеров на проектах без ранней миграции:

- `20260418120000_ensure_clusters_for_postgrest.sql` — идемпотентно `public.clusters`, RLS, bucket `cluster_covers`.

### Социальный граф (follow)

Спека: `docs/supabase/SPEC_SUPABASE_SOCIAL_GRAPH_AND_ACCOUNT.md`.

| Файл | Назначение |
|------|------------|
| `20260420120000_profile_follows_social_graph.sql` | `profile_follows`, счётчики на `profiles`, триггеры ±1, RLS, RPC `follow_user` / `unfollow_user` / `is_following_user`, списки подписчиков/подписок. |
| `20260421100000_social_graph_blocks_notifications_feed_reconcile.sql` | `profile_blocks`, `notification_events` (dedupe), `can_user_interact`, расширенный `follow_user` (блоки, 200/h, нотификация), `list_following_feed_enriched_cursor`, `reconcile_profile_follow_counts` (service_role). |

### In-app уведомления

**Spec:** [SPEC_IN_APP_NOTIFICATIONS.md](SPEC_IN_APP_NOTIFICATIONS.md) · **Process:** [notifications.md](../business/notifications.md)

| Файл | Назначение |
|------|------------|
| `20260729120000_notifications_reactions_comments.sql` | `notifications`, триггеры post/comment reactions, `list_notifications_enriched_cursor`, `mark_notifications_read`. |
| `20260802130000_notifications_last_30_days.sql` | Retention 30 дней в list RPC. |
| `20260830210000_notifications_follow_unread.sql` | `user_follow` в ленте, `follow_user` → `notifications`, backfill из `notification_events`, `is_following_actor` в list RPC, `count_unread_notifications`. |
| `20260830211000_fix_notifications_list_following_check.sql` | Fix 403: `is_following_user()` вместо прямого SELECT `profile_follows` в list RPC. |
| `20260830212000_fix_follow_user_perform_notification.sql` | Fix 42601: `follow_user` — `PERFORM upsert_notification` вместо bare `SELECT`. |
| `20260830220000_booking_notifications.sql` | Booking kinds в `notifications`, triggers + cron visit reminders, `booking_id` в list RPC, auto_close default `no_show`. |
| `20260830230000_booking_client_reminders.sql` | `booking_reminder_client` (24h/3h/1h/30m), `booking_notifications_scan_scheduled` cron wrapper. |
| `20260830240000_booking_get_enriched_by_id.sql` | `get_booking_enriched_for_viewer` — deep link / tap на запись по id. |

### Push / FCM (device tokens)

**Spec:** [SPEC_PUSH_FCM.md](SPEC_PUSH_FCM.md)

| Файл | Назначение |
|------|------------|
| `20260901180000_push_device_tokens.sql` | `push_device_tokens` — upsert FCM token per user/device; RLS owner-only. |
| `20260905220000_push_outbox_drain.sql` | claim/mark RPC for Edge `drain_push_outbox` (FCM HTTP v1). |
| `20260906010000_booking_no_auto_complete_staff_id.sql` | Auto-close only `no_show` (never completed); `staff_id` in host list. |
| `20260906020000_booking_push_client_reschedule_attendance_duty_folders.sql` | Booking → `push_outbox`; client reschedule; attendance `duty_only_punch` + folders bootstrap. |
| `20260906111000_drop_booking_reviews.sql` | Drop unused `booking_reviews` (no in-app reviews). |
| `20260906120000_replace_booking_staff_absences.sql` | Atomic `replace_booking_staff_absences(jsonb)` — host absences in one txn. |
| `20260906140000_fix_upsert_notification_overload.sql` | Drop ambiguous 7-arg `upsert_notification` (likes 400 on `set_post_reaction`). |

### Attendance (посещаемость) — ядро

**Спека:** [SPEC_ATTENDANCE_SYSTEM.md](SPEC_ATTENDANCE_SYSTEM.md) | **Навигатор:** `migrations/_attendance/README.md`  
**Процесс:** `docs/business/attendance.md`

| Файл | Назначение |
|------|------------|
| **`20260903120000_attendance_schema.sql`** | Enums, folders/workplaces/memberships/punches/absences/punch_type_defs, PostGIS location, indexes. |
| **`20260903120100_attendance_rls_grants.sql`** | RLS + GRANT; punches DML только через RPC. |
| **`20260903120200_attendance_rpc.sql`** | bootstrap, invite/accept/reject/archive/reinvite, ack, punch submit/cancel, absence upsert. |
| **`20260905130000_attendance_payroll_duty_ot.sql`** | `payroll_rules` / `duty_roster` jsonb, `base_salary_tenge`, OT table + RPC; bootstrap расширен. |
| **`20260905200000_attendance_chat_push_analytics_correction.sql`** | group chat, CLOVER_CARD invite/rules, notify+push_outbox, analytics/timesheet RPC, punch correction. |
| **`20260905210000_attendance_chat_card_kinds.sql`** | `chat_message_kind` + `chat_message_attendance_cards`. |
| **`20260905210100_attendance_rich_chat_reinvite_corrections_list.sql`** | rich post card, reinvite DM+notify, `attendance_list_corrections`, enriched `attendance_card`. |
| **`20260906130000_booking_attendance_prod_ready.sql`** | Atomic punch types, server payroll preview; booking enriched `service_id`/`staff_id`; availability exclude id для reschedule. |

#### Ключевые особенности:
*   **0 трафика для неучастников** — нет полезного SELECT без ownership/membership.
*   **Geofence на сервере** — `ST_DWithin` в `submit_attendance_punch`.
*   **Outbox** — `client_punch_id` / `client_request_id` идемпотентность.
*   **config_version / ack_version** — punch блокируется до ack; payroll/duty не бампят config.

### Чат и сообщения (messages)

Подробный разбор файлов и потока данных — **`migrations/_chat/README.md`**.

| Файл | Назначение |
|------|------------|
| `20260417160000_chat_schema.sql` | Таблицы `chat_conversations`, `chat_participants`, `chat_messages`, реакции, вложения, ссылки на посты; RLS без прямого DML с клиента. |
| `20260417161000_chat_rpc.sql` | RPC чата (создание dm/group, списки enriched, отправка текста, read markers, поиск и т.д.). |
| `20260417162000_chat_search_fts.sql` | FTS по сообщениям в чатах пользователя. |
| `20260421103000_chat_media_storage_send_attachments.sql` | Bucket `chat_media`, `send_message_with_attachments`. |
| `20260422140000_chat_relax_storage_attach_cap.sql` | Коррекция лимитов Storage для вложений. |
| `20260423120000_chat_get_message_enriched.sql` | `get_message_enriched` — одно сообщение в формате списка. |
| `20260423180000_chat_realtime_publication.sql` | Таблицы чата в `supabase_realtime` для `postgres_changes`. |
| `20260425120000_chat_broadcast_message_enriched.sql` | Broadcast `message_enriched` после INSERT (`realtime.send` на `chat_thread_<conversation_id>`). |
| `20260425180000_chat_client_message_id.sql` | `client_message_id`, reconcile оптимистичных отправок. |
| `20260426100000_chat_read_by_peer.sql` (+ `…26110000…`) | Поле `read_by_peer` в enriched-сообщениях. |
| `20260426120000_chat_child_tables_conversation_id.sql` | `conversation_id` на дочерних таблицах сообщений. |
| `20260426130000_chat_participants_replica_identity_full.sql` (+ `20260429120000_ensure_chat_participants_replica_identity_full.sql`) | `REPLICA IDENTITY FULL` на `chat_participants` для полноты WAL/Realtime UPDATE. |
| `20260427120100_chat_participants_select_no_rls_recursion.sql` | Политика SELECT без рекурсии RLS. |
| `20260427130000_chat_participants_grant_select_authenticated.sql` | `GRANT SELECT` для REST peer-курсоров. |
| `20260428120000_mark_conversation_read_monotonic_cursor.sql` | Монотонный курсор в `mark_conversation_read`. |
| `20260429140000_chat_broadcast_peer_read.sql` | Broadcast `peer_read` при сдвиге read-курсора (мгновенные галочки у отправителя). |
| `20260908180000_count_unread_chat_messages.sql` | `count_unread_chat_messages()` — суммарный unread для бейджа кабинета (web). |
| `20260908190000_chat_attachments_r2_public_url.sql` | `chat_message_attachments.public_url` + RPC attachments bucket `r2`. |
| `20260830250000_chat_reactions_rpc.sql` | `toggle_message_reaction`; колонка `my_reactions` в `list_messages_enriched` / `get_message_enriched`. |
| `20260830260000_chat_messenger_basics.sql` | `delete_message`, `edit_message` — soft-delete и правка текста своих сообщений. |
| `20260830270000_chat_attachments_client_message_id.sql` | `send_message_with_attachments` + `p_client_message_id` — reconcile optimistic media/file. |
| `20260831100000_auth_login_helpers.sql` | `auth_is_email_registered`, `auth_resolve_login_email` — OTP только новым / логин по нику. |
| `20260831120000_auth_current_user_has_password.sql` | `auth_current_user_has_password()` — для Настроек: «Установить» vs «Сбросить пароль». |
| `20260831130000_auth_email_otp_cooldown.sql` | `auth_email_otp_cooldown` + `auth_claim_email_otp_send` / `auth_email_otp_retry_after` — кулдаун переотправки OTP 400с. |
| `20260831140000_auth_is_email_fully_registered.sql` | `auth_is_email_fully_registered` — блок регистрации только для завершённых аккаунтов (пароль/OAuth). |
| `20260831150000_auth_fully_registered_password_flag.sql` | fully_registered = `clover_password_set` meta или OAuth (не `encrypted_password` после OTP). |

### Ленты / RPC (часть)
- `20260411150000_list_user_feed_enriched_rpc.sql`, `20260411160000_hot_feed_enriched_profile_cursor.sql`, `20260416120000_user_feed_cluster_filter.sql` и др. — см. имена файлов в `supabase/migrations/`.

### Профессиональный граф (Relations & Hiring)

**Спека:** `docs/supabase/SPEC_RELATIONS_SYSTEM.md` (создана 2026-05-04).

| Файл | Назначение |
|------|------------|
| **`20260504054611_add_relations_system.sql`** | Таблица `public.relations` (каноническая пара `from_account_id < to_account_id`), флаги `hiring_enabled` / `open_for_memberships` в `profiles`. **Intent:** `request_relation(..., 'hire' \| 'join')`. **State machine:** `update_relation_status`. **Чтение:** RLS `SELECT` по участию в паре; DML только через `security definer` RPC. Доп. RPC: `get_my_relation_with(p_other)` — одна строка между `auth.uid()` и `p_other`. |

### Booking (онлайн-запись)

**Спека:** `docs/supabase/SPEC_BOOKING_SYSTEM.md` | **Навигатор:** `migrations/_booking/README.md`

| Файл | Назначение |
|------|------------|
| `20260725120000_marker_tag_booking.sql` | Тег аккаунта `booking` в `marker_tags` (кнопка «Записаться»). |
| `20260908150000_booking_calendar_tag_and_staff_rpcs.sql` | Тег `bookingCalendar` + `list_my_staff_booking_hosts` / `list_my_staff_bookings_enriched`. Спека: [SPEC_BOOKING_CALENDAR_STAFF.md](SPEC_BOOKING_CALENDAR_STAFF.md) |
| `20260908160000_marker_tag_admin_worker_groups.sql` | Силовые теги: `group_key` `admin` / `worker` вместо `account`. |
| `20260908194706_attendance_tag_powers_impl.sql` | Теги `attendance` / `attendanceWork`; гейты create/invite/update/punch; bootstrap `has_attendance_work_tag`. |
| `20260909033323_resources_marker_tag.sql` | Admin-тег `resources` в `marker_tags` (местоположения / фильтры). |
| `20260908170000_booking_staff_invite_kinds.sql` | `chat_message_kind.booking_staff_invite` + `chat_message_booking_cards`. |
| `20260908171000_booking_staff_invite_rpc.sql` | `booking_staff_invites` + invite/accept/reject/cancel + `booking_card` в enriched. Спека: [SPEC_BOOKING_STAFF_INVITE.md](SPEC_BOOKING_STAFF_INVITE.md) |
| **`20260726120000_booking_schema.sql`** | Таблицы booking, EXCLUDE constraints, helpers (`booking_resolve_staff_day_window`, …), `pg_trgm` indexes. |
| **`20260726120100_booking_rls_grants.sql`** | RLS + GRANT для authenticated. |
| **`20260726120200_booking_rpc.sql`** | `create_booking`, `get_booking_availability`, enriched lists, status, analytics. |
| `20260830160000_booking_create_confirmed_instant.sql` | `create_booking` → сразу `confirmed` + `confirmed_at` (instant booking). |
| `20260830170000_posts_booking_service_link.sql` | `posts.booking_service_id`, trigger same-host, RLS read via post, `set_post_booking_service`, enriched detail. |
| `20260830190000_post_root_json_booking_service.sql` | `post_enriched_root_json` + `booking_service`; лента ивентов и detail из одного JSON. |
| `20260830195000_bonus_earn_without_program_switch.sql` | Начисление бонусов за визит не зависит от `bonus_program_status` (только услуга). |
| `20260830200000_drop_bonus_program_status.sql` | Удалён `bonus_program_status`; бонусы только по полям услуги. |

#### Ключевые особенности:
*   **Per-staff schedule** — `booking_staff_schedule` + fallback на account settings.
*   **Blocked slots** — `booking_blocked_slots` без fake bookings.
*   **History** — `booking_history` на create/status change.
*   **Reviews** — сняты (`20260906111000_drop_booking_reviews.sql`); in-app отзывы не делаем.
*   **Notifications** — backlog (не v1).

#### Ключевые особенности реализации (Relations):
*   **Canonical pair** — уникальность `(from_account_id, to_account_id)` без дублей направления.
*   **Strict state machine** — `active` / `rejected` только получатель при `pending`; `terminated` только из `active` (оба участника).
*   **RPC для изменений** — `request_relation`, `update_relation_status`; повторный `pending` только если строка была `rejected` или `terminated` (`ON CONFLICT DO UPDATE … WHERE`).
*   **Row count** после upsert — явная проверка `GET DIAGNOSTICS … = ROW_COUNT` (нет зависимости от `FOUND` в вложенных блоках).

### Dictionaries / sync_meta (removed)

| Файл | Назначение |
|------|------------|
| `20260730120000_sync_meta_currencies.sql` | Создание `sync_meta` + currencies (currencies позже удалены). |
| `20260730130000_profiles_embed_sync_meta.sql` | View `profiles_with_sync_meta`, fn `sync_meta_payload()`. |
| `20260830120000_drop_sync_meta.sql` | **Удаление** `sync_meta`, view и function — клиент на enum catalogs. |

### Support (сайт)

| Файл | Назначение |
|------|------------|
| `20260908120000_support_requests.sql` | Таблица `support_requests` + RLS insert-only для формы `/support`. Spec: [SPEC_SUPPORT_REQUESTS.md](SPEC_SUPPORT_REQUESTS.md) |