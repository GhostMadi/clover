## Clusters

Миграции (не переносить из корня):

### Основная схема

- `../20260402120000_clusters.sql` — таблица **`public.clusters`** (привязка к автору, обложка, счётчики), триггеры `clusters_set_updated_at`, синхронизация **`profiles.cluster_count`**, RLS, bucket **`cluster_covers`** и политики Storage.

### Совместимость и ремонт на старых БД

- `../20260418120000_ensure_clusters_for_postgrest.sql` — идемпотентное восстановление `clusters`, RLS и bucket `cluster_covers`, если ранняя миграция не применялась.

### Ленты и фильтрация

- `../20260416120000_user_feed_cluster_filter.sql` — фильтрация пользовательской ленты по кластерам (см. также **`_posts/README.md`**).

### Удаление аккаунта / storage кластеров

- `../20260418130000_reset_account_storage_posts_clusters.sql` — очистка префиксов Storage для постов и кластеров в рамках цепочки `reset_account` (актуальное поведение RPC — см. **`MIGRATIONS_INDEX.md`**, финальная миграция про отключение полного wipe).

### Связь с постами

Посты ссылаются на кластер через схему в **`../20260402140000_posts_post_media_engagement.sql`** (таблица `posts` и счётчики на `clusters`).
