## Сообщения чата (chat messages)

Миграции **не переносить** из корня `supabase/migrations/` — Supabase учитывает только файлы по timestamp в корне. Эта папка — навигатор по домену **чаты / сообщения**.

### Идея доступа к данным

- Таблицы `chat_*` включены под **RLS**, прямой `insert/update/delete` из клиента **не задуман** (`revoke … from authenticated`).
- Основной путь — **`SECURITY DEFINER`** RPC (`send_message`, `send_message_with_attachments`, списки, поиск и т.д.), см. `20260417161000_chat_rpc.sql` и последующие итерации.
- Вложения: байты в **Storage** bucket `chat_media`, метаданные — `chat_message_attachments`, см. `20260421103000_chat_media_storage_send_attachments.sql`.

### Миграции по порядку внедрения

| Файл | Назначение |
|------|------------|
| `../20260417160000_chat_schema.sql` | Enum’ы (`chat_message_kind`: `text`, `media`, `file`, `post_ref`, `system`), таблицы `chat_conversations`, `chat_participants`, `chat_messages`, `chat_message_reactions`, `chat_message_attachments`, `chat_message_post_refs`; индексы; RLS + revoke прямого DML. |
| `../20260417161000_chat_rpc.sql` | RPC: `chat_assert_participant`, `create_dm`, `create_group`, участники, **`list_messages_enriched`**, **`send_message`** (ранняя версия сигнатуры), **`list_conversations_enriched`**, **`mark_conversation_read`**, поиск и др.; все через definer + `row_security off`. |
| `../20260417162000_chat_search_fts.sql` | Полнотекстовый поиск по чату (FTS для сообщений участника). |
| `../20260421103000_chat_media_storage_send_attachments.sql` | Bucket **`chat_media`**, политики Storage; RPC **`send_message_with_attachments`** — коммит сообщения + строки вложений после загрузки файлов. |
| `../20260422140000_chat_relax_storage_attach_cap.sql` | Ослабление лимита размера/типов под реальные вложения (уточнение поверх bucket). |
| `../20260423120000_chat_get_message_enriched.sql` | **`get_message_enriched(message_id)`** — одна строка в том же JSON-форме, что `list_messages_enriched` (дельта-синхрон без полного перечитывания ленты). |
| `../20260423180000_chat_realtime_publication.sql` | Добавление таблиц чата в publication **`supabase_realtime`** — клиентские **`postgres_changes`** по INSERT/UPDATE в сообщениях и связках. |
| `../20260425120000_chat_broadcast_message_enriched.sql` | Broadcast на канал темы **`chat_thread_<conversation_id>`**, событие **`message_enriched`** — enriched JSON после INSERT (обёртка над тем же содержимым, что enriched-списки). |
| `../20260425180000_chat_client_message_id.sql` | Колонка **`client_message_id`** (уникальный nullable), обновление **`send_message`** — reconcile оптимистичных отправок с клиентским UUID. |
| `../20260426100000_chat_read_by_peer.sql` | RPC **`list_messages_enriched`** / **`get_message_enriched`**: поле **`read_by_peer`** у исходящих сообщений (курсор собеседника в той же беседе). |
| `../20260426110000_chat_read_by_peer_join_same_conversation.sql` | Уточнение join для **`read_by_peer`** (одна беседа). |
| `../20260426120000_chat_child_tables_conversation_id.sql` | Дочерние таблицы сообщений с **`conversation_id`** (удобство фильтров Realtime / запросов). |
| `../20260426130000_chat_participants_replica_identity_full.sql` | **`REPLICA IDENTITY FULL`** для **`chat_participants`** — полнота **old/new** в WAL для Realtime UPDATE (важно для подписок и отладки). |
| `../20260427120100_chat_participants_select_no_rls_recursion.sql` | SELECT-политика **`chat_participants`** без рекурсии RLS (PostgREST / REST GET peer-курсоров). |
| `../20260427130000_chat_participants_grant_select_authenticated.sql` | **`GRANT SELECT`** на **`chat_participants`** для **`authenticated`** — клиентский REST для **`peerLastReadCursors`** (без grant PostgREST отдаёт 403). |
| `../20260428120000_mark_conversation_read_monotonic_cursor.sql` | **`mark_conversation_read`**: курсор **`last_read_message_id`** только «вперёд» по шкале сообщений `(created_at, id)`, без отката на старый UUID. |
| `../20260429120000_ensure_chat_participants_replica_identity_full.sql` | Идемпотентное повторное **`REPLICA IDENTITY FULL`** на **`chat_participants`** (если на окружении пропускали раннюю миграцию). |
| `../20260429140000_chat_broadcast_peer_read.sql` | Broadcast **`peer_read`** на topic **`chat_thread_<conversation_id>`** после UPDATE строки участника (**`last_read_message_id` / `last_read_at`**) — мгновенное обновление галочек у отправителя (аналог скорости **`message_enriched`**). |

### Realtime и «прочитано» (галочки у отправителя)

Клиентский тред открывает **один** канал Supabase Realtime с именем **`chat_thread_<conversation_id>`** (совпадает с topic в `realtime.send`).

| Механизм | Назначение |
|----------|------------|
| **Postgres Changes** (`postgres_changes`) | Таблицы из publication **`supabase_realtime`** (см. `../20260423180000_chat_realtime_publication.sql`): новые сообщения, реакции, вложения, **UPDATE** в **`chat_participants`**. На UPDATE в части WAL в `new` может не быть `conversation_id` — клиент подписан **без** server-side фильтра по диалогу и сам отсекает чужие строки после **merge old+new**. |
| **Broadcast `message_enriched`** | Триггер после INSERT в **`chat_messages`** (`../20260425120000_chat_broadcast_message_enriched.sql`): тот же JSON, что **`get_message_enriched`**, доставляется без ожидания репликации списков. |
| **Broadcast `peer_read`** | Триггер после UPDATE в **`chat_participants`**, когда сдвигается курсор прочитанного (`../20260429140000_chat_broadcast_peer_read.sql`). Payload: **`conversation_id`**, **`user_id`** (кто прочитал), **`last_read_message_id`**, **`last_read_at`**. Отправитель сопоставляет это с локальными исходящими и включает **`read_by_peer`**. |

**REST (не Realtime):** начальные курсоры собеседников при открытии треда — **`GET`** по **`chat_participants`** (нужны GRANT + политика SELECT). RPC **`mark_conversation_read`** обновляет только строку **текущего** пользователя; собеседник видит результат через **`postgres_changes`** и/или **`peer_read`**.

**Если галочки не двигаются:** проверить, что применены publication, триггеры broadcast, **`REPLICA IDENTITY FULL`**, политика **`realtime.messages`** для broadcast (см. конец `../20260425120000_chat_broadcast_message_enriched.sql`), и что клиент подписан на канал **`chat_thread_<uuid>`**.

### Связь с приложением (Flutter)

- URL проекта и anon key — `lib/core/config/supabase_config.dart` (должен совпадать с Dashboard и с `project-ref` после `supabase link`).
- Edge Function **`send_chat_attachments`** — см. `supabase/functions/send_chat_attachments/` и секцию deploy в корневом `supabase/README.md`.
- Тред чата: **`ChatThreadCubit`** — `onPostgresChanges` по **`chat_messages`** / **`chat_participants`**, **`onBroadcast`** для **`message_enriched`** и **`peer_read`**; диагностика по имени лога **`ChatRead`** (`lib/feature/chat/debug/chat_read_receipt_debug_log.dart`).

### См. также

- Общий индекс: `supabase/MIGRATIONS_INDEX.md` (раздел про чат).
- Посты и репосты в чат: `chat_message_post_refs` → таблица `posts` из домена **`_posts/README.md`**.
