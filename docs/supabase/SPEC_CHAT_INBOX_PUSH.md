# Chat inbox realtime + DM push

**Process:** [chats.md](../business/chats.md) · [notifications.md](../business/notifications.md)  
**Migration:** `20260909180806_chat_inbox_broadcast_push.sql`

## Broadcast

| Topic | Event | When |
|-------|--------|------|
| `chat_thread_<conversationId>` | `message_enriched` | INSERT message (as before) |
| `chat_inbox_<userId>` | `inbox_changed` | INSERT message → every member; peer read → other members |
| `chat_thread_<conversationId>` | `peer_read` | as before |

Inbox payload (message): `conversation_id`, `message_id`, `sender_id`, `kind`, `preview`, `created_at`.  
Inbox payload (read): `conversation_id`, `reason=peer_read`, `reader_id`.

Client: **один** Realtime-канал `chat_inbox_<uid>` в `ChatUnreadCubit` → бейдж + in-app баннер + soft-refresh списка чатов + **thread cache sync** (`get_message_enriched` → upsert local thread cache / watermark; skip when thread already open or `peer_read`).

## Push

On INSERT, for each participant **≠ sender**:

`push_outbox` row:
- `kind` = `chat_message`
- `title` = sender username
- `body` = text preview / «Фото» / «Пост» / …
- `payload` = `{ kind, conversation_id, message_id, sender_id, peer_username }` (stringy in FCM data)

Drain: existing `drain_push_outbox` Edge + cron.
