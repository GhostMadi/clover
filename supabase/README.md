## Supabase (migrations + edge functions)

### 1) Apply SQL migrations
Run from repo root:

```bash
supabase db push
```

If you use hosted Supabase (remote), link your project first:

```bash
supabase link
supabase db push
```

### 2) Deploy Edge Functions
Functions added:
- `create_post`
- `register_post_view`
- `register_post_send`
- `refresh_hot_posts_24h`
- `send_chat_attachments` (чат / вложения)

Deploy:

```bash
supabase functions deploy create_post
supabase functions deploy register_post_view
supabase functions deploy register_post_send
supabase functions deploy refresh_hot_posts_24h
supabase functions deploy send_chat_attachments
```

### 3) Set function secrets (required)
`create_post`, `register_post_view`, `register_post_send` use user JWT (Authorization header) + anon key.
`refresh_hot_posts_24h` uses service role key.

```bash
supabase secrets set SUPABASE_URL=... SUPABASE_ANON_KEY=... SUPABASE_SERVICE_ROLE_KEY=...
```

### 4) Notes / mapping to migrations
Навигаторы по доменам (SQL остаётся только в корне `migrations/`):

- Посты: `migrations/_posts/README.md`
- Комментарии: `migrations/_comments/README.md`
- Кластеры: `migrations/_clusters/README.md`
- **Чат и сообщения**: `migrations/_chat/README.md` (в т.ч. **Realtime**: `postgres_changes`, broadcast **`message_enriched`** / **`peer_read`**, read receipts).

Быстрые ссылки на первые файлы домена:

- Posts schema + RLS + counters: `migrations/20260402140000_posts_post_media_engagement.sql`
- Views events + batch flush: `migrations/20260402150000_post_view_events.sql`
- Storage for post media + sends events: `migrations/20260407193000_posts_storage_views_sends.sql`
- Hot feed MV + refresh: `migrations/20260407201000_hot_feed_materialized_view.sql`
- Chat schema + RPC entrypoint: `migrations/20260417160000_chat_schema.sql`, `migrations/20260417161000_chat_rpc.sql`

