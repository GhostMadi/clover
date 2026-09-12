# Аудит бэкендов Clover — план и чеклист

**Статус:** рабочий план + исполнение  
**Точка входа правил бэка (критично, always):** [`clover-backend-feature`](../code/rules/clover-backend-feature.mdc)  
**Детали цикла:** [`clover-supabase-cycle`](../code/rules/clover-supabase-cycle.mdc)  
**Ориентир фаз продукта:** [../business/_feature-lifecycle-checklist.md](../business/_feature-lifecycle-checklist.md) · `clover-harmony` / `clover-supabase-docs` / `clover-catalog-l10n`

---

## Порядок доменов (не прыгать)

| # | Домен | Продукт | Бэк-док | Риск сейчас |
|---|--------|---------|---------|-------------|
| 0 | **Booking** (точки / schedule) | [booking-points.md](../business/booking-points.md) | [booking-points.md](booking-points.md), SPEC_BOOKING_* | Только spot: хвосты docs ↔ live |
| 1 | **Attendance** | [attendance.md](../business/attendance.md) | [SPEC_ATTENDANCE_SYSTEM.md](SPEC_ATTENDANCE_SYSTEM.md) | Высокий: много RPC, web+mobile |
| 2 | **Resources** (locations / filters) | [locations.md](../business/locations.md), [resources-guide.md](../business/resources-guide.md) | migrations + business | Средний: каталог vs свободный текст |
| 3 | **Chat / inbox / push** | [chats.md](../business/chats.md), [notifications.md](../business/notifications.md) | SPEC_CHAT_*, SPEC_PUSH_*, SPEC_IN_APP_* | Высокий: edge + RLS |
| 4 | **Auth / email** | [authentication.md](../business/authentication.md) | [SPEC_EMAIL_AUTH.md](SPEC_EMAIL_AUTH.md) | Средний: hooks/secrets |
| 5 | **Posts / events / social** | [publications.md](../business/publications.md) | SPEC_POSTS_*, SPEC_SUPABASE_SOCIAL_* | Средний: объём, spot |
| 6 | **Support / R2 / Relations** | support, media | SPEC_SUPPORT_*, SPEC_R2_*, SPEC_RELATIONS_* | Низкий / legacy |

На каждый домен: **проверить → зафиксировать findings → починить только нарушения цикла/чистоты** (не косметику).

---

## Чеклист на один домен

### A. Жизненный цикл (продукт)

- [ ] Есть `docs/business/…` с ролями и фазами (создать → действовать → учесть → выйти)
- [ ] Строка в [features-catalog.md](../business/features-catalog.md)
- [ ] Нет дыры «создали, а выгнать/вернуть нельзя» без явного «вне скоупа»

### B. Контракт бэка

- [ ] Spec в `docs/supabase/` (или запись в [MIGRATIONS_INDEX.md](MIGRATIONS_INDEX.md))
- [ ] Ссылка продукт ↔ бэк (не дублировать сценарии в SQL-доке)
- [ ] Миграции только `supabase/migrations/<timestamp>_….sql`

### C. Схема и правда данных

- [ ] Колонки `snake_case`; справочники = **английский ключ**, без `name_ru` / локали в Postgres
- [ ] FK / check на ключи где нужен каталог
- [ ] RLS включён; политики = роли продукта (не «спрятать кнопку на клиенте»)
- [ ] Тяжёлая логика (слоты, punch, инвайты, статусы) — **RPC / constraints**, не только клиент

### D. Гармония фронтов

- [ ] Flutter-модель и web API читают **тот же контракт** (имена полей / enum-ключи)
- [ ] Нет второго «особого» пайплайна «только для сайта» в обход RLS

### E. Чистота (анти-кастом)

- [ ] Нет одноразовых костылей без записи во «вне скоупа» / «сознательно позже»
- [ ] Fallback’ы (legacy host-only и т.п.) помечены и конечны
- [ ] Spec ↔ live DB не разъехались (spot: PK, ключевые RPC)

### F. Результат домена

| Вердикт | Meaning |
|---------|---------|
| ✅ | Цикл живой, доки ↔ схема ↔ RPC сходятся |
| 🟡 | Живой, но есть хвосты (docs / fallback / позже) |
| 🔴 | Дыра в цикле или безопасность / правда данных |

Findings писать ниже в § Журнал.

---

## Журнал проходов

### 0 · Booking (spot)

- Дата: 2026-09-11  
- Вердикт: 🟡 (после points: модель ОК; хвосты absences/blocks host-level, mobile → default point — в доке)  
- Действие: docs добиты (SPEC / INDEX / booking-points)

### 1 · Attendance

- Дата: 2026-09-11  
- Вердикт: 🟡 → правки must-fix  
- Findings: RPC-only гейты тегов обходились PostgREST; RU в `attendance_payroll_preview`  
- Fixes: `20260911185500_attendance_audit_rls_payroll_keys.sql` (revoke DML + EN keys); web/mobile localize payroll  
- Осталось (docs/later): company exit, `accepted` alias UI, SPEC §4 полный список RPC, duty README stale

### 2 · Resources (locations / filters)

- Дата: 2026-09-12  
- Вердикт: 🟡 → must-fix address mapping  
- Findings: mobile create писал кириллицу в `address_primary` / латиницу в `address_cyrillic` (наоборот web)  
- Fixes: mobile `location_create_page` + web `createLocationQuick` = контракт resources; [locations.md](locations.md); `20260911200000_locations_address_comments.sql`  
- Осталось (docs/later): zones delivery вне скоупа; `resources` tag = UI gate

### 3 · Chat / inbox / push

- Дата: 2026-09-12  
- Вердикт: 🟡 → must-fix EN preview/push (chat) + booking/attendance  
- Findings: RU в `chat_broadcast` preview / push body; booking/attendance push producers тоже RU  
- Fixes: chat EN keys; booking/attendance EN keys; drain localize; catalog Push live; **web `bindChatInboxRealtime`**  
- Осталось: —

### 4 · Auth / email

- Дата: 2026-09-12  
- Вердикт: 🟢 Send Email Hook + OTP 3/hour в бою; multi-session login alerts  
- Findings: web password/OTP parity; product был single-session mobile; SMTP без серверного hourly gate  
- Fixes:  
  - **Send Email Hook** → Edge `send_email_hook` → Resend REST (`RESEND_API_KEY`) + HMAC (`SEND_EMAIL_HOOK_SECRET`); claim RPC service_role; soft peek на клиентах  
  - auth-api / AuthRepository rate-limit + OTP cooldown UI (web `AuthOtpStep`, mobile)  
  - **multi-session** primary/guest; `account_login_events` + notify confirm/revoke/change_password  
- Процесс / flow: [SPEC_EMAIL_AUTH.md](SPEC_EMAIL_AUTH.md) § Архитектура + § Выполненные шаги  
- Осталось: Phone/WhatsApp OTP later; UI polish ошибок OTP later  
- Done (2026-09-12): secrets set + `send_email_hook` redeploy + Hook в Auth UI

### 5 · Posts / events / social

- Дата: 2026-09-12  
- Вердикт: 🟡 → reactions + web owner archive/delete + archives list  
- Findings: reaction RPC без visibility; web без archive/delete / списка архива  
- Fixes: reactions RPC-only; web owner menu; `/app/settings/archives/posts` + restore  
- Осталось: SPEC `block_user` vs live REST blocks; legacy Storage

### 6 · Support / R2 / Relations

- Дата: 2026-09-12  
- Вердикт: 🟡 → docs must-fix (Relations removed)  
- Findings: SPEC/INDEX описывали Relations как live; Support не в catalog  
- Fixes: SPEC_RELATIONS = REMOVED; INDEX drop row; features-catalog Support  
- Осталось: admin UI support; rate-limit anon insert (зафиксировано later в SPEC)

### Хвосты (закрыто must-fix)

| Приоритет | Хвост | Домен |
|-----------|--------|--------|
| 1 | ~~Auth Hook / Edge gate для OTP~~ → done (`send_email_hook`, 3/hour) | Auth |
| — | ~~Support rate-limit~~ ✅ | Support |
| — | ~~Multi-session + login alerts~~ ✅ primary/guest + revoke Auth session | Auth |
| — | ~~Web архивы~~ ✅ | Posts |
| — | ~~Web `inbox_changed`~~ ✅ | Chat |

---

## Паритет клиентов ↔ бэк (после аудита)

| Изменение бэка | Web | Mobile | Статус |
|----------------|-----|--------|--------|
| Email OTP **3/hour** + Send Email Hook | `auth-api` + `AuthOtpStep` | `AuthRepository` + OTP cooldown | ✅ бой (Hook + secrets + deploy) |
| Login events primary/guest + revoke | notifications + `report_account_login` | то же | ✅ |
| Attendance payroll EN keys | `payroll-labels.ts` | `attendance_payroll_*` | ✅ |
| Locations address latin/cyrillic | `locations-api` | `location_create_page` | ✅ |
| Chat/push EN preview keys | localize | localize | ✅ |
| Post reactions RPC-only | `reactions-api` | `post_repository` | ✅ |
| **Booking points** (`point_id`) | workspace `/p/[id]/…` | list → hub + services/schedule | ✅ MVP mobile 2026-09-12 |

---

## Далее (очередь)

Порядок: не прыгать; сначала то, без чего прод хромает.

| # | Что | Где | Зачем |
|---|-----|-----|--------|
| **1** | ~~Send Email Hook + secrets + deploy~~ ✅ | Auth | Flow/процесс → [SPEC_EMAIL_AUTH.md](SPEC_EMAIL_AUTH.md) |
| **2** | ~~Mobile: booking points UI~~ ✅ list→hub + point-scoped services/schedule | `lib/feature/_booking_/booking_points/` | — |
| **3** | ~~Mobile: inbox/analytics + app-bar switcher~~ ✅ | booking | — |
| **4** | Product/docs хвосты attendance (company exit, SPEC §4 RPC list, duty README) | docs | Не security; ясность цикла |
| **5** | ~~Booking absences / blocks per-point~~ ✅ migration + web/mobile | booking | — |
| **6** | Phone / WhatsApp OTP gate (как email) | Auth later | Сознательно later |
| **7** | Support admin UI; UI polish OTP errors | web / mobile | Не блокер бэка |
| **8** | Posts: SPEC `block_user` vs live; legacy Storage | posts | Spot docs |

**Не делать «заодно»:** новый кастомный слой; чинить соседний домен без строки в этой таблице.

---

## Как чинить (дисциплина)

1. Сначала док продукта, если дыра в цикле  
2. Потом `docs/supabase/` + миграция  
3. Потом клиенты (web / mobile) под контракт  
4. Не чинить «заодно» соседний домен  
5. Не вводить новый кастомный слой «чтобы быстрее»

Правило агента (вход): [`clover-backend-feature`](../code/rules/clover-backend-feature.mdc).  
Детали: [`clover-supabase-cycle`](../code/rules/clover-supabase-cycle.mdc).
