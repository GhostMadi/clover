# Cloudflare R2 — единая точка загрузки медиа

**Связано с процессом:** медиа постов / профиль / кластеры / чат (публичные URL в Postgres).  
**Карта стека / хостов:** [../business/tech-stack.md](../business/tech-stack.md).

---

## Идея

Все **новые** байты идут в **Cloudflare R2** через один контракт:

1. Edge `get-upload-url` → presigned PUT  
2. Клиент PUT напрямую в R2  
3. В БД — публичный URL (и для чата ещё `fileKey` + `public_url`)

Supabase Storage больше не используется для новых загрузок с клиента.  
Видео-постеры (`upload_post_media_poster`) не развиваем.

## Edge Functions

| Функция | Назначение |
|---------|------------|
| `get-upload-url` | Presigned PUT (15 мин) → `{ uploadUrl, publicUrl, fileKey }` |
| `delete-r2-objects` | Удаление по `urls` / `fileKeys` (только ключи с `/{uid}/`) |
| `delete_post` | Чистит R2 media поста (best-effort) → `delete_owned_post` |

Shared: `supabase/functions/_shared/r2.ts`

Gateway: `verify_jwt = false`, JWT внутри через `requireSupabaseUser`.

## Секреты (имена)

| Secret | Значение / заметка |
|--------|-------------------|
| `R2_ACCESS_KEY_ID` | R2 API token |
| `R2_SECRET_ACCESS_KEY` | R2 API secret |
| `R2_ENDPOINT` | S3 endpoint аккаунта Cloudflare |
| `R2_BUCKET_NAME` | `clover-app` |
| `R2_PUBLIC_URL` | цель: `https://media.clover.com.kz` (после Custom Domain; без `/` в конце) |

Публичный CDN-хост и DNS: [tech-stack.md](../business/tech-stack.md).

## Клиенты (одно место)

| Платформа | Модуль |
|-----------|--------|
| Flutter | `lib/core/storage/r2_storage_service.dart` |
| Web | `web/src/lib/r2-storage.ts` |

Через них: профиль, посты, кластеры, чат-вложения.

## Чат

- Upload → R2 folder `chat_media`
- RPC `send_message_with_attachments` с `bucket: r2`, `path: fileKey`, `public_url`
- Миграция: `20260908190000_chat_attachments_r2_public_url.sql`
- Старые `chat_media` Storage-вложения читаются как раньше

## Удаление поста

1. `R2StorageService.deleteObjects` / `deleteFromR2` / Edge `delete_post`  
2. Legacy cleanup через `delete_owned_post` (старый Supabase Storage)

## Deploy

```bash
supabase functions deploy get-upload-url --project-ref wewrosbaxhkukbefjwzf
supabase functions deploy delete-r2-objects --project-ref wewrosbaxhkukbefjwzf
supabase functions deploy delete_post --project-ref wewrosbaxhkukbefjwzf
```
