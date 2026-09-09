# Tech stack & сервисы Clover

**Статус:** живой справочник  
**Зачем:** одно место — какие стеки, какие внешние сервисы, откуда идут хосты. Не код и не продуктовые сценарии.

При смене сервиса / домена / деплоя — **сначала обновить этот файл**, потом спеки.

---

## Гибрид: логика vs медиа

| Слой | Кто | За что |
|------|-----|--------|
| **Бизнес-логика** | Supabase (Postgres, RLS, Auth, Realtime, Edge Functions) | данные, права, RPC, пресайны |
| **Объектное хранение** | Cloudflare R2 (bucket `clover-app`) | байты медиа (фото, вложения…) |
| **Сайт** | Vercel | Next.js `web/` на `clover.com.kz` |
| **DNS зона** | Cloudflare | NS для `clover.com.kz` |
| **Регистратор домена** | Unihost.kz | оплата домена; NS делегированы на Cloudflare |

Клиенты **не** видят ключи R2: только Edge `get-upload-url` / `delete-r2-objects`.  
Контракт медиа: [SPEC_R2_DIRECT_UPLOAD.md](../supabase/SPEC_R2_DIRECT_UPLOAD.md).

---

## Карта платформ

| Платформа | Стек | Прод-ветка | Хост / доставка |
|-----------|------|------------|-----------------|
| **Мобилка** | Flutter (iOS / Android) | `mobile-production` | TestFlight / сторы (GitHub Actions) |
| **Сайт / кабинет** | Next.js в `web/` | `web-production` | Vercel → **https://clover.com.kz** |
| **Бэкенд** | Supabase | миграции / functions в репо | `https://wewrosbaxhkukbefjwzf.supabase.co` |
| **Медиа (байты)** | Cloudflare R2 `clover-app` | Edge Secrets `R2_*` | цель: **https://media.clover.com.kz** |
| **Общий trunk** | доки + контракты | `main` | не деплоит прод мобилки/сайта |

Ветки подробно: [git-branches.md](git-branches.md).

---

## Хосты и DNS

### Роли по домену `clover.com.kz`

| Роль | Кто |
|------|-----|
| Регистратор | **Unihost.kz** |
| DNS (NS) | **Cloudflare** — `cruz.ns.cloudflare.com`, `gabe.ns.cloudflare.com` |
| Сайт | **Vercel** (A/CNAME в зоне Cloudflare) |
| Почта (MX / SPF / DKIM) | записи в Cloudflare (были у UniHost → перенесены/просканированы; **не ломать** Resend) |
| Медиа CDN | R2 Custom Domain → **media.clover.com.kz** (после Active зоны) |

Сделано (2026-09):

1. Домен добавлен в Cloudflare (Connect domain / Free).  
2. У Unihost NS сменены с `ns*.unihost.kz` на Cloudflare NS выше.  
3. Ждём статус зоны **Active** и пропагацию.

После Active:

1. R2 → bucket `clover-app` → Settings → Custom Domains → **media.clover.com.kz**.  
2. Edge Secret: `R2_PUBLIC_URL=https://media.clover.com.kz` (без trailing `/`).

### Таблица хостов

| Хост / зона | Кто держит | Для чего |
|-------------|------------|----------|
| **clover.com.kz** / **www** | Cloudflare DNS → Vercel | Сайт + кабинет `/app` |
| **media.clover.com.kz** | Cloudflare R2 Custom Domain | Публичные медиа URL (цель) |
| **wewrosbaxhkukbefjwzf.supabase.co** | Supabase | API, Auth, Realtime, Edge |
| **welcome@clover.com.kz** | Resend + DNS (MX/SPF/DKIM в Cloudflare) | From OTP-писем |
| **localhost:3000** | локально | Dev сайта |

Сайт-деплой: [website-deploy.md](website-deploy.md).  
Мобилка-деплой: [mobile-deploy.md](mobile-deploy.md).

---

## Сервисы (внешние)

| Сервис | Роль в Clover | Где секреты / ключи | Док |
|--------|---------------|---------------------|-----|
| **Supabase** | БД, RLS, Auth, Realtime, Edge | Dashboard + anon в клиенте | [docs/supabase/](../supabase/) |
| **Cloudflare** | DNS + R2 | Dashboard; R2 API tokens → Edge Secrets | этот файл + SPEC_R2 |
| **Cloudflare R2** | Bucket `clover-app` | `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY`, `R2_ENDPOINT`, `R2_BUCKET_NAME`, `R2_PUBLIC_URL` | [SPEC_R2](../supabase/SPEC_R2_DIRECT_UPLOAD.md) |
| **Vercel** | Хостинг Next.js | `NEXT_PUBLIC_*` | [website-deploy.md](website-deploy.md) |
| **Unihost.kz** | Регистратор домена (не DNS) | панель регистратора | — |
| **Resend** | SMTP / email OTP | Supabase Custom SMTP | [email-authentication.md](email-authentication.md) |
| **Google** | Sign-In | Google Cloud + Supabase Auth | [website.md](website.md) |
| **Firebase / FCM** | Push | Firebase + Edge drain | [SPEC_PUSH_FCM.md](../supabase/SPEC_PUSH_FCM.md) |
| **Yandex Maps** | Карта | ключ моб / `NEXT_PUBLIC_YANDEX_MAPS_API_KEY` | [website-cabinet.md](website-cabinet.md) |
| **Meta WhatsApp** | SMS hook + webhook | Edge Secrets | supabase functions |
| **Apple / ASC** | TestFlight | GitHub Actions secrets | [mobile-deploy.md](mobile-deploy.md) |
| **GitHub** | Репо + CI | Actions secrets | `.github/workflows/` |

Секреты **не** писать сюда — только имена.

### R2 Edge Secrets (имена)

| Secret | Назначение |
|--------|------------|
| `R2_ACCESS_KEY_ID` | R2 API token |
| `R2_SECRET_ACCESS_KEY` | R2 API secret |
| `R2_ENDPOINT` | S3 endpoint аккаунта Cloudflare |
| `R2_BUCKET_NAME` | `clover-app` |
| `R2_PUBLIC_URL` | `https://media.clover.com.kz` (после Custom Domain) |

---

## Мобилка (Flutter)

| Что | Как |
|-----|-----|
| Код | `lib/`, `android/`, `ios/`, `pubspec.yaml` |
| Backend | тот же Supabase project |
| Медиа | `R2StorageService` → Edge |
| Auth | Google + Phone/WhatsApp OTP + Email OTP |
| Push | Firebase Messaging |
| Карты | Yandex MapKit |
| Прод | `mobile-production` |

---

## Веб / сайт (Next.js)

| Что | Как |
|-----|-----|
| Код | `web/` |
| URL | `https://clover.com.kz` |
| Backend | тот же Supabase |
| Медиа | `web/src/lib/r2-storage.ts` → Edge |
| Auth | Supabase Auth |
| Карты | Yandex JS API |
| Прод | `web-production` → Vercel |

---

## Бэкенд (Supabase)

| Зона | Путь / хост |
|------|-------------|
| Project URL | `https://wewrosbaxhkukbefjwzf.supabase.co` |
| Миграции | `supabase/migrations/` |
| Edge Functions | `supabase/functions/` |
| Спеки | `docs/supabase/` |

Ключевые Edge: `get-upload-url`, `delete-r2-objects`, `delete_post`, `send_sms_hook`, `whatsapp_webhook`, `drain_push_outbox`.

---

## Потоки «кто куда»

```
Мобилка / Сайт
    │
    ├─ Auth / данные / Realtime ──► Supabase
    │
    ├─ Медиа ──► Edge get-upload-url ──► PUT R2 (clover-app)
    │                ▲                      │
    │                └── R2_* secrets       └── публично: media.clover.com.kz
    │
    ├─ Email OTP ──► Supabase Auth ──► Resend
    │
    └─ (моб) Push ──► FCM ◄── drain_push_outbox
```

```
Браузер ──► clover.com.kz (Vercel)
DNS ──► Cloudflare NS (регистратор: Unihost)
Медиа URL ──► media.clover.com.kz (R2 Custom Domain)
```

---

## Чеклист DNS / R2 (текущий шаг)

- [x] Гибрид Supabase + R2; секреты R2 (кроме финального `R2_PUBLIC_URL`) в Edge  
- [x] Домен в Cloudflare; NS `cruz` / `gabe`  
- [x] У Unihost делегирование на Cloudflare NS  
- [ ] Зона Cloudflare = **Active** (проверить в Dashboard)  
- [x] Custom Domain R2: `media.clover.com.kz` → bucket `clover-app` (Active, Enabled; объект отдаёт 200)  
- [x] Secret `R2_PUBLIC_URL=https://media.clover.com.kz`  
- [x] DNS: `media.clover.com.kz` резолвится (на Mac — DNS `1.1.1.1` / `8.8.8.8`; роутерский NXDOMAIN возможен)  
- [ ] Проверка в приложении: пост/аватар открывается по `https://media.clover.com.kz/…`  
- [ ] Почта: OTP с `welcome@` после смены NS (MX/SPF/DKIM на месте)

---

## Что обновлять при изменениях

1. Строка в таблицах выше.  
2. Узкая спека / деплой-док.  
3. Имена env в Vercel / Edge / GitHub Actions.

---

## Связанные документы

- [website-deploy.md](website-deploy.md) · [mobile-deploy.md](mobile-deploy.md) · [git-branches.md](git-branches.md)  
- [SPEC_R2_DIRECT_UPLOAD.md](../supabase/SPEC_R2_DIRECT_UPLOAD.md)  
- [SPEC_EMAIL_AUTH.md](../supabase/SPEC_EMAIL_AUTH.md) · [SPEC_PUSH_FCM.md](../supabase/SPEC_PUSH_FCM.md)  
- [features-catalog.md](features-catalog.md)
