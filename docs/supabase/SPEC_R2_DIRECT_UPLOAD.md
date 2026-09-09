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

## CORS бакета (обязательно для веба)

Браузер с `clover.com.kz` делает **прямой PUT** на `*.r2.cloudflarestorage.com`.  
Без CORS → в DevTools: **Failed to fetch** (preflight OPTIONS без `Access-Control-Allow-Origin`).

Cloudflare Dashboard → **R2** → bucket **`clover-app`** → **Settings** → **CORS policy**:

```json
[
  {
    "AllowedOrigins": [
      "https://clover.com.kz",
      "https://www.clover.com.kz",
      "http://localhost:3000"
    ],
    "AllowedMethods": ["GET", "PUT", "HEAD"],
    "AllowedHeaders": ["Content-Type", "Content-Length"],
    "ExposeHeaders": ["ETag", "Location"],
    "MaxAgeSeconds": 3600
  }
]
```

Проверка:

```bash
curl -sI -X OPTIONS \
  "https://<ACCOUNT_ID>.r2.cloudflarestorage.com/clover-app/probe" \
  -H "Origin: https://www.clover.com.kz" \
  -H "Access-Control-Request-Method: PUT" \
  -H "Access-Control-Request-Headers: content-type"
```

В ответе должны быть `access-control-allow-origin` и `access-control-allow-methods`.

## Presigned URL (SDK)

AWS SDK JS v3 по умолчанию тащит `x-amz-checksum-crc32` в URL — R2 / браузерный PUT ломаются.  
В `_shared/r2.ts`: `requestChecksumCalculation: WHEN_REQUIRED` + `unhoistableHeaders` для checksum.

## Клиенты (одно место)

| Платформа | Модуль |
|-----------|--------|
| Flutter | `lib/core/storage/r2_storage_service.dart` (прямой PUT в R2) |
| Web | `web/src/lib/r2-storage.ts` → **`/api/r2/upload`** (сервер PUT в R2; без CORS бакета) |

Через них: профиль, посты, кластеры, чат-вложения.

CORS на бакете всё ещё полезен (прямой PUT / отладка), но веб больше **не зависит** от него.

## Показ картинок на вебе

Браузер грузит `https://media.clover.com.kz/...` через same-origin rewrite:

- `toWebMediaSrc` → `/media/...`
- `next.config.ts` rewrite → `https://media.clover.com.kz/...`

Так превью работают, даже если DNS/`media.` в браузере режется (на мобилке native DNS часто ок).

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
