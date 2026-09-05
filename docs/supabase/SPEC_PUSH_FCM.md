# Push / FCM — Supabase spec

**Process:** [notifications.md](../business/notifications.md)  
**In-app:** [SPEC_IN_APP_NOTIFICATIONS.md](SPEC_IN_APP_NOTIFICATIONS.md)  
**Migration:** `20260901180000_push_device_tokens.sql`

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

## 2. Server (v2 backlog)

- Edge Function / worker reads tokens by `user_id`, sends via FCM HTTP v1
- Outbox for failed sends
- No client INSERT except token registry

---

## 3. iOS setup (manual)

1. Xcode → Runner → Signing & Capabilities → **Push Notifications**
2. Upload APNs key in Firebase Console → Project Settings → Cloud Messaging
3. `UIBackgroundModes` → `remote-notification` (Info.plist)

---

## 4. Android

- `google-services.json` + `com.google.gms.google-services` plugin
- `POST_NOTIFICATIONS` (API 33+) — runtime permission via FCM plugin
