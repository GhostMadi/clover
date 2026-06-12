# SQL migrations (`supabase/migrations/`)

Файлы с префиксом timestamp Supabase применяет из **этого каталога** (`supabase db push`). Подпапки здесь — только документация и навигаторы; сами `.sql` **не переносим** в `_posts/` и т.п.

## По доменам

| Раздел | Файл |
|--------|------|
| Чат, сообщения, **Realtime** (`postgres_changes`, broadcast **`message_enriched`** / **`peer_read`**, галочки прочитано) | [_chat/README.md](_chat/README.md) |
| Посты | [_posts/README.md](_posts/README.md) |
| Комментарии | [_comments/README.md](_comments/README.md) |
| Кластеры | [_clusters/README.md](_clusters/README.md) |

Общий индекс имён миграций: [../MIGRATIONS_INDEX.md](../MIGRATIONS_INDEX.md).
