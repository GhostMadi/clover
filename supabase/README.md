## Supabase (код бэкенда)

**Документация** (спеки, index): [`docs/supabase/`](../docs/supabase/README.md)

**Код:**

- `migrations/` — SQL (CLI применяет только отсюда)
- `functions/` — Edge Functions
- `config.toml` — локальный конфиг

### Apply migrations

```bash
supabase db push
```

Hosted: `supabase link` → `supabase db push`

### Deploy Edge Functions

```bash
supabase functions deploy create_post
supabase functions deploy register_post_view
supabase functions deploy register_post_send
supabase functions deploy refresh_hot_posts_24h
supabase functions deploy send_chat_attachments
supabase functions deploy send_sms_hook
supabase functions deploy whatsapp_webhook
```

### Secrets

```bash
supabase secrets set SUPABASE_URL=... SUPABASE_ANON_KEY=... SUPABASE_SERVICE_ROLE_KEY=...
```

Навигаторы по доменам в `migrations/_*/README.md`. Полный index — [`docs/supabase/MIGRATIONS_INDEX.md`](../docs/supabase/MIGRATIONS_INDEX.md).
