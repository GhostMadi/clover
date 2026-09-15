# Push / FCM — Supabase spec

**Process:** [notifications.md](../business/notifications.md) · [attendance.md](../business/attendance.md)  
**In-app:** [SPEC_IN_APP_NOTIFICATIONS.md](SPEC_IN_APP_NOTIFICATIONS.md)  
**Migrations:** `20260901180000_push_device_tokens.sql`, `20260905200000_…` (`push_outbox`), `20260905220000_push_outbox_drain.sql`, `20260915120000_push_device_tokens_one_per_platform.sql`, `20260915173140_push_device_tokens_platform_web.sql`  
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
| `platform` | `ios` \| `android` \| `web` |
| `updated_at` | Last sync |

Unique: `(user_id, platform)` — один активный FCM token на платформу (ротации заменяют; иначе дубли tray).  
Также `(user_id, token)` для идемпотентности строки.

---

## 2. Server — outbox + drain worker

### Queue

`attendance_notify` / `booking_enqueue_push` / chat broadcast пишут in-app `notifications` **и** строку в **`push_outbox`**.

| Column | Purpose |
|--------|---------|
| `user_id` | Recipient |
| `kind` | EN event key (`booking_created_host`, `attendance_invite`, `chat_message`, …) |
| `title` / `body` | **EN keys** (not locale). Drain localizes for FCM tray. |
| `payload` | Dynamic fields (`service_title`, `workplace_name`, `starts_at`, …) → FCM `data` |
| `sent_at` | null = pending |
| `attempts` / `last_error` | retry / diagnostics |

Миграция EN keys: `20260912080000_push_outbox_booking_attendance_en_keys.sql` (+ chat preview earlier).

Клиент **не** читает/пишет `push_outbox` (только service_role).

### Edge Function `drain_push_outbox`

1. Auth: `Authorization: Bearer <SERVICE_ROLE_KEY>` **или** `x-push-worker-secret: <PUSH_WORKER_SECRET>`
2. `push_outbox_claim_batch(limit)` — `FOR UPDATE SKIP LOCKED`, `attempts++`
3. Для каждой строки: **все** tokens из `push_device_tokens` для `user_id` (ios/android/web — без фильтра платформы)
4. FCM HTTP v1 `projects/{id}/messages:send`
5. Успех → `push_outbox_mark_sent`; ошибка → `push_outbox_mark_failed`
6. Invalid token (`UNREGISTERED` / `NOT_FOUND`) → `push_device_tokens_delete_token`
7. Нет токенов → mark sent (in-app уже есть; не крутим forever)

`attempts >= 8` — больше не claim.

### Secrets (Supabase Edge)

Дискретные `FCM_*` (JSON через CLI часто ломает `private_key`):

```bash
supabase secrets set FCM_PROJECT_ID=clover-52112
supabase secrets set FCM_CLIENT_EMAIL=firebase-adminsdk-...@clover-52112.iam.gserviceaccount.com
# PEM одной строкой с литералами \n:
supabase secrets set FCM_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
supabase secrets set PUSH_WORKER_SECRET="$(openssl rand -hex 32)"
```

OAuth Google → поле `access_token` (snake_case).

### Delivery (мгновенно, без внешнего cron)

1. Insert в `push_outbox` → trigger `trg_push_outbox_request_drain` → `pg_net` POST на Edge `drain_push_outbox`  
2. Vault secret name: **`push_worker_secret`** (= Edge `PUSH_WORKER_SECRET`)  
3. GitHub Action — не нужен для доставки (опциональный ручной Run workflow)

Миграция: `20260915130000_push_outbox_instant_drain.sql`.

### Deploy

```bash
supabase functions deploy drain_push_outbox
supabase db push
# one-time ops: vault.create_secret('<PUSH_WORKER_SECRET>', 'push_worker_secret')
```

Не класть service account / worker secret в git или в SQL миграции.

### FCM `data` open contract (клиент)

Drain кладёт `kind` + flatten `payload` в FCM `data`. Клиент открывает через `NotificationOpenRouter` (не отдельный switch в dashboard).

| kind | Обязательные keys в `data` | Intent |
|------|----------------------------|--------|
| social `post_*` / `comment_*` | `post_id` | post |
| `user_follow` | `actor_id` | profile |
| `booking_*` | `booking_id` | booking detail (viewer role на бэке) |
| `attendance_*` | `workplace_id` (если есть) | attendance pending / settings |
| `chat_message` | `conversation_id` | chat |
| `account_login` | — | no nav (CTA in-app) |

Миграция ids в payload: `booking_id` в `booking_notification_payload`; `actor_id` в social outbox.

---

## 3. iOS setup (manual)

1. Xcode → Runner → Signing & Capabilities → **Push Notifications**  
   Entitlements: Debug → `development` (`Runner.entitlements`); **Release / TestFlight / App Store** → `production` (`RunnerRelease.entitlements`, `RunnerProfile.entitlements`). Неверный `aps-environment` → `FCM token empty`.
2. Upload APNs **.p8** key in Firebase Console → Project Settings → Cloud Messaging
3. `UIBackgroundModes` → `remote-notification` (Info.plist)
4. Проверка push: **реальный iPhone** (Debug). Симулятор часто даёт `FCM token empty (APNs not ready)`.
5. В логе должно быть: `[Push] FCM upserted · ios · …` — иначе строки в `push_device_tokens` нет и drain некому слать.

---

## 4. Android

- `google-services.json` + `com.google.gms.google-services` plugin
- `POST_NOTIFICATIONS` (API 33+) — runtime permission via FCM plugin
- Канал уведомлений: системный default FCM (без жёсткого `channel_id` в worker)

---

## 5. Web (Next.js / `web/`)

Тот же Firebase project (`clover-52112`). Flutter `DefaultFirebaseOptions` **не** содержит web app — создать Web app в Firebase Console и задать env.

| Step | Where |
|------|--------|
| Config | `web/src/lib/firebase/config.ts` ← `NEXT_PUBLIC_FIREBASE_*` |
| Register + upsert | `web/src/features/push/lib/web-push.ts` (`platform=web`) |
| Bootstrap | `WebPushBootstrap` in cabinet layout (after login) |
| Detach | `detachWebPushForSignOut` before `auth.signOut()` |
| Background SW | `web/public/firebase-messaging-sw.js` + `/firebase-messaging-config.js` (env bake) |

### Env (Vercel / `.env.local` — не коммитить)

```
NEXT_PUBLIC_FIREBASE_API_KEY=
NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN=   # clover-52112.firebaseapp.com
NEXT_PUBLIC_FIREBASE_PROJECT_ID=clover-52112
NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET=clover-52112.firebasestorage.app
NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID=1044695605376
NEXT_PUBLIC_FIREBASE_APP_ID=        # 1:…:web:… after creating Web app
NEXT_PUBLIC_FIREBASE_VAPID_KEY=     # Cloud Messaging → Web Push certificates
```

Без полного набора клиент **no-op** (in-app колокольчик работает).  
Drain уже шлёт на любой token пользователя — отдельный filter по platform не нужен.

Package: `firebase` (JS SDK) в `web/package.json`.
