# Push / FCM — Supabase spec

**Process:** [notifications.md](../business/notifications.md) · [attendance.md](../business/attendance.md)  
**In-app:** [SPEC_IN_APP_NOTIFICATIONS.md](SPEC_IN_APP_NOTIFICATIONS.md)  
**Migrations:** `20260901180000_push_device_tokens.sql`, `20260905200000_…` (`push_outbox`), `20260905220000_push_outbox_drain.sql`  
**Edge:** `supabase/functions/drain_push_outbox`

---

## 1. Client (Flutter)

| Step | Where |
|------|--------|
| Firebase init | `main.dart` |
| FCM init + permission | `AppPushMessagingService.init()` |
| Upsert token | after sign-in / token refresh |
| Delete token | **before** `auth.signOut()` (`detachForSignOut`) |

Packages: `firebase_core`, `firebase_messaging`.

Table: **`public.push_device_tokens`** — RLS own rows only.

| Column | Purpose |
|--------|---------|
| `user_id` | Owner |
| `token` | FCM registration token |
| `platform` | `ios` \| `android` |
| `updated_at` | Last sync |

Unique: `(user_id, token)`.

---

## 2. Server — outbox + drain worker

### Queue

`attendance_notify` (и другие продюсеры) пишут in-app `notifications` **и** строку в **`push_outbox`**.

| Column | Purpose |
|--------|---------|
| `user_id` | Recipient |
| `kind` / `title` / `body` | Push notification |
| `payload` | jsonb → FCM `data` (string values) |
| `sent_at` | null = pending |
| `attempts` / `last_error` | retry / diagnostics |

Клиент **не** читает/пишет `push_outbox` (только service_role).

### Edge Function `drain_push_outbox`

1. Auth: `Authorization: Bearer <SERVICE_ROLE_KEY>` **или** `x-push-worker-secret: <PUSH_WORKER_SECRET>`
2. `push_outbox_claim_batch(limit)` — `FOR UPDATE SKIP LOCKED`, `attempts++`
3. Для каждой строки: tokens из `push_device_tokens`
4. FCM HTTP v1 `projects/{id}/messages:send`
5. Успех → `push_outbox_mark_sent`; ошибка → `push_outbox_mark_failed`
6. Invalid token (`UNREGISTERED` / `NOT_FOUND`) → `push_device_tokens_delete_token`
7. Нет токенов → mark sent (in-app уже есть; не крутим forever)

`attempts >= 8` — больше не claim.

### Secrets (Supabase Edge)

Один из вариантов:

```bash
# A) целиком JSON service account (Firebase Console → Project settings → Service accounts → Generate key)
supabase secrets set FIREBASE_SERVICE_ACCOUNT_JSON="$(cat path/to/service-account.json)"

# B) по полям
supabase secrets set FCM_PROJECT_ID=clover-52112
supabase secrets set FCM_CLIENT_EMAIL=firebase-adminsdk-...@clover-52112.iam.gserviceaccount.com
supabase secrets set FCM_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"

# Рекомендуется для cron без service_role в URL:
supabase secrets set PUSH_WORKER_SECRET="$(openssl rand -hex 32)"
```

Уже должны быть: `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`.

### Deploy + schedule

```bash
supabase functions deploy drain_push_outbox
supabase db push   # миграция claim/mark RPC
```

Cron (раз в 1–2 мин), пример:

```bash
curl -X POST "$SUPABASE_URL/functions/v1/drain_push_outbox" \
  -H "x-push-worker-secret: $PUSH_WORKER_SECRET" \
  -H "Content-Type: application/json" \
  -d '{"limit":40}'
```

Варианты расписания: **GitHub Action** [`.github/workflows/drain_push_outbox.yml`](../../.github/workflows/drain_push_outbox.yml) (cron `*/2`) / внешний cron / Supabase Scheduled Functions.  
Repo secrets: `SUPABASE_URL`, `PUSH_WORKER_SECRET` (значение = Edge secret).  
Не класть service account / `PUSH_WORKER_SECRET` в git или в SQL миграции.

---

## 3. iOS setup (manual)

1. Xcode → Runner → Signing & Capabilities → **Push Notifications**  
   Entitlements: Debug/Release → `aps-environment=development`; Profile/TestFlight → `production` (`Runner.entitlements` / `RunnerRelease.entitlements` / `RunnerProfile.entitlements`).
2. Upload APNs **.p8** key in Firebase Console → Project Settings → Cloud Messaging
3. `UIBackgroundModes` → `remote-notification` (Info.plist)
4. Проверка push: **реальный iPhone** (Debug). Симулятор часто даёт `FCM token empty (APNs not ready)`.
5. В логе должно быть: `[Push] FCM upserted · ios · …` — иначе строки в `push_device_tokens` нет и drain некому слать.

---

## 4. Android

- `google-services.json` + `com.google.gms.google-services` plugin
- `POST_NOTIFICATIONS` (API 33+) — runtime permission via FCM plugin
- Канал уведомлений: системный default FCM (без жёсткого `channel_id` в worker)
