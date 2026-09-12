# Chat inbox realtime + DM push

**Process:** [chats.md](../business/chats.md) · [notifications.md](../business/notifications.md)  
**Migration:** `20260909180806_chat_inbox_broadcast_push.sql`

## Broadcast

| Topic | Event | When |
|-------|--------|------|
| `chat_thread_<conversationId>` | `message_enriched` | INSERT message (as before) |
| `chat_inbox_<userId>` | `inbox_changed` | INSERT message → every member; peer read → other members |
| `chat_thread_<conversationId>` | `peer_read` | as before |

Inbox payload (message): `conversation_id`, `message_id`, `sender_id`, `sender_username`, `kind`, `preview`, `created_at`.  
Inbox payload (read): `conversation_id`, `reason=peer_read`, `reader_id`.

`preview` for placeholders = **English keys** (`photo` / `file` / `post` / `message` / `system`); free text messages keep user text. Clients localize.

Client:
- **Flutter:** один канал `chat_inbox_<uid>` в `ChatUnreadCubit` → бейдж + баннер + soft-refresh списка + thread cache sync.
- **Web:** `bindChatInboxRealtime()` в `chat-unread.ts` (из `cabinet-shell`) → `CHAT_UNREAD_CHANGED` → бейдж + refresh списка; poll 120s как backup.

## Push

On INSERT, for each participant **≠ sender**:

`push_outbox` row:
- `kind` = `chat_message`
- `title` = sender username
- `body` = same as `preview` (EN keys or free text)
- `payload` = `{ kind, conversation_id, message_id, sender_id, peer_username, message_kind, preview_key }`

Drain (`drain_push_outbox`): maps EN placeholder keys → RU for FCM tray (locale-first until multi-l10n).

**Migration (EN keys):** `20260911201000_chat_inbox_preview_en_keys.sql`  
**Earlier:** `20260909180806_chat_inbox_broadcast_push.sql`, `20260910200000_chat_media_broadcast_after_attachments.sql`
