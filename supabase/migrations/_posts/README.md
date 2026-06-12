## Posts

Миграции (не переносить из корня):

### Базовая схема ленты и медиа

- `../20260402140000_posts_post_media_engagement.sql` — тип `media_type`, таблицы `posts`, `post_media`, дерево **`comments`** (в т.ч. входит в общую миграцию постов), лайки/сохранения постов (исторические `post_likes` / `post_saves`), счётчики, индексы лент, RLS.
- `../20260402150000_post_view_events.sql` — `post_view_events`, батч **`flush_post_view_events_batch()`** (cron/service_role).
- `../20260407193000_posts_storage_views_sends.sql` — bucket **`post_media`**, пути `posts/{post_id}/{…}`, `post_send_events`, триггер `sends_count`.

### Горячая лента

- `../20260407201000_hot_feed_materialized_view.sql` — материализованное представление **`hot_posts_24h`**, функция **`refresh_hot_posts_24h()`**, при наличии — `pg_cron`.

### Реакции на посты

- `../20260408130000_post_reactions_like_dislike.sql` — таблица **`post_reactions`** (`like` | `dislike`), счётчики на `posts`.
- `../20260408131000_hot_feed_switch_to_post_reactions.sql` — перевод hot-feed на новые реакции.
- `../20260409180000_post_reactions_set_and_batch.sql` — RPC **`set_post_reaction`**, батчи.
- `../20260409183000_drop_toggle_post_reactions_rpcs.sql` — удаление устаревших toggle-RPC.
- `../20260415140000_post_reactions_select_match_posts_visibility.sql` — согласование видимости при выборке реакций с RLS постов.

### Отображение и пресеты

- `../20260409120000_posts_display_aspect_preset.sql` — колонки пресета отображения медиа.
- `../20260409143000_revert_posts_display_aspect_preset.sql` — откат/коррекция пресета.

### Ленты и enriched RPC

- `../20260411150000_list_user_feed_enriched_rpc.sql` — пользовательская лента enriched.
- `../20260411160000_hot_feed_enriched_profile_cursor.sql` — hot feed с курсором и профилем.
- `../20260411230000_get_post_enriched.sql` — **`get_post_enriched`** — один пост с JSON для клиента.
- `../20260416120000_user_feed_cluster_filter.sql` — фильтр ленты по кластерам.

### Сохранённые посты

- `../20260411190000_saved_posts_backend_rpc.sql` — бэкенд RPC для сохранений.
- `../20260411200000_post_saves_author_sees_savers.sql` — автор видит кто сохранил (политики/RPC по домену сохранений).
- `../20260411210000_list_my_saved_posts_exclude_deleted.sql` — сохранёнки без удалённых постов.
- `../20260411220000_enriched_feed_my_saved.sql` — enriched лента «мои сохранения».
- `../20260415120000_list_my_saved_posts_exclude_archived.sql` — исключение архива из сохранёнок.

### Профиль и счётчики

- `../20260416100000_profiles_post_count.sql` — **`profiles.post_count`**, триггеры на `posts`.

### Удаление аккаунта и storage постов

- `../20260417100000_reset_account_hard_delete_content.sql`, `../20260418130000_reset_account_storage_posts_clusters.sql` — цепочка `reset_account` (частично отключена позже), очистка storage постов — см. также `MIGRATIONS_INDEX.md` про **`20260419000000_disable_reset_account_content_wipe.sql`**.

### Комментарии к постам

Отдельный навигатор: **`../_comments/README.md`** (таблица `comments`, реакции, RPC списков).

### Чаты и шаринг поста

Ссылка поста в сообщении — **`chat_message_post_refs`** и RPC чата: **`../_chat/README.md`**.
