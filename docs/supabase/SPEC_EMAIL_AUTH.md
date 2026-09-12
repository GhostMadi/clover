# Email Auth: Send Email Hook (Resend) + OTP rate limit

**Продукт:** [../business/email-authentication.md](../business/email-authentication.md)  
**Клиент:** `lib/core/auth/`, `web/src/features/auth/`  
**Секреты:** Resend API Key / Hook secret — только Dashboard / Edge secrets, **не в репозитории**  
**Статус (2026-09-12):** ✅ внедрено в бой — Hook + Edge secrets + deploy `send_email_hook`; лимит **3 OTP / email / час**

---

## Цель

Транзакционные OTP-письма Clover с **welcome@clover.com.kz** через **Resend**, с **серверным** лимитом: **не больше 3 писем на один email за скользящий час**.

Стандартный SMTP-путь Auth **заменён** для OTP на Auth Hook → Edge Function → Resend REST API (защита от спама до отправки провайдеру).

Гейтим только **отправку** OTP (Auth `signInWithOtp` → Send Email Hook).  
**Не** в этом проходе: `verifyOTP`, установка пароля, Phone/WhatsApp.

---

## Архитектура отправки OTP и rate limiting

| Компонент | Роль |
|-----------|------|
| **Supabase Auth** | `signInWithOtp`, `verifyOTP`, сессия |
| **Auth Hook: Send Email** | HTTPS POST → Edge `send_email_hook` |
| **Edge `send_email_hook`** | HMAC (`SEND_EMAIL_HOOK_SECRET`) → claim лимита → Resend (`RESEND_API_KEY`) |
| **RPC** | `auth_email_otp_retry_after` (peek UI); `auth_claim_email_otp_send` (**только** `service_role`) |
| **Flutter / Web** | eligibility + soft peek; не пишут в лог отправок |
| **UniHost** | DNS зона `clover.com.kz` |

### Flow

```
[Клиент]
   │  запрос OTP (signInWithOtp)
   ▼
[Supabase Auth]
   │  перехват Send Email Hook
   ▼
[HTTPS → Edge: send_email_hook]
   ├── 1. Проверка HMAC (SEND_EMAIL_HOOK_SECRET)
   ├── 2. Лимит ≤ 3 / час на email
   │      ├─ превышен → Auth error 429 (Retry in N seconds)
   │      └─ ok → claim send
   └── 3. Resend REST API → welcome@clover.com.kz → inbox
```

Когда Hook **включён**, он **заменяет** Custom SMTP для этих писем: шаблоны Dashboard SMTP не используются — HTML собирает hook.

---

## Выполненные шаги настройки (процесс)

1. **Resend API Key** — в панели Resend создан REST-токен отправки (`RESEND_API_KEY`) для Edge (не SMTP-пароль из Auth Dashboard).
2. **Auth Hook** — Authentication → Hooks → **Send Email** → HTTPS →  
   `https://wewrosbaxhkukbefjwzf.supabase.co/functions/v1/send_email_hook`  
   + секрет вебхука `SEND_EMAIL_HOOK_SECRET` (`v1,whsec_…`).
3. **Edge Secrets** (без значений в git):

```bash
supabase secrets set \
  RESEND_API_KEY="re_…" \
  SEND_EMAIL_HOOK_SECRET="v1,whsec_…" \
  --project-ref wewrosbaxhkukbefjwzf
```

4. **Deploy:**

```bash
supabase functions deploy send_email_hook --project-ref wewrosbaxhkukbefjwzf
```

5. **БД:** миграция `20260912170000_auth_email_otp_hourly_limit.sql` (`auth_email_otp_sends` + claim/retry RPC).
6. **Клиенты:** soft peek + маппинг 429 / cooldown UI (mobile + web register/forgot).

### Зачем так

| Плюс | Смысл |
|------|--------|
| Антиспам | Блок повторных OTP на сервере до Resend |
| Безопасность | Только подписанные вызовы Auth (HMAC) |
| Доставляемость | Прямой Resend HTTP + логи в Resend; домен/DNS как раньше |

---

## Лимит OTP

| Правило | Значение |
|---------|----------|
| На один email | **max 3** send / rolling **1 hour** |
| На IP | нет (сознательно later) |
| Register vs reset | **один** hourly cap на email; eligibility разная (см. ниже) |
| Verify / set password | **не** лимитим здесь |

Таблица: `public.auth_email_otp_sends` (`email`, `sent_at`).  
Миграция: `20260912170000_auth_email_otp_hourly_limit.sql` (заменяет 400с cooldown из `20260831130000`).

| RPC | Кто вызывает | Смысл |
|-----|--------------|--------|
| `auth_email_otp_retry_after(email, p_max_per_hour=3)` | anon / authenticated / service_role | секунды до слота; `0` = можно |
| `auth_claim_email_otp_send(email, p_max_per_hour=3)` | **только service_role** (hook) | `0` = записали send; иначе wait |
| `auth_release_last_email_otp_send(email)` | **только service_role** (hook) | откат записи, если Resend упал |

Клиент **не** вызывает claim (иначе можно сжечь слоты без письма / double-count с hook).

---

## Eligibility (не путать с rate limit)

| Сценарий | Кому шлём код |
|----------|----------------|
| Регистрация | Только если email **не** завершённый аккаунт (`auth_is_email_fully_registered` = false) |
| Сброс пароля | Только если email **уже есть** (`auth_is_email_registered` = true) |
| Ежедневный логин | OTP **не** используется |

Оба сценария делят **один** счётчик 3/час на тот же email.

Прочие RPC без изменений: `auth_is_email_registered`, `auth_resolve_login_email`, `auth_current_user_has_password`, `auth_is_email_fully_registered`.

---

## Edge: `send_email_hook`

Путь: `supabase/functions/send_email_hook/`  
`verify_jwt = false` (подпись Standard Webhooks, как `send_sms_hook`).

**Secrets (Edge Functions → Secrets):**

| Secret | Назначение |
|--------|------------|
| `SEND_EMAIL_HOOK_SECRET` | `v1,whsec_…` из Auth Hooks UI |
| `RESEND_API_KEY` | Resend API key |
| `CLOVER_OTP_FROM_EMAIL` | optional, default `welcome@clover.com.kz` |
| `CLOVER_OTP_FROM_NAME` | optional, default `Clover` |

`SUPABASE_URL` / `SUPABASE_SERVICE_ROLE_KEY` — inject платформой.

Phone/WhatsApp — **later** (`send_sms_hook` отдельно).

---

## Домен (Resend)

| | |
|--|--|
| Домен | `clover.com.kz` |
| Статус | **Verified** |
| Отправитель | `welcome@clover.com.kz` |

DNS / DKIM / SPF / DMARC — UniHost / Resend Domains. Полные ключи **не** в git.

---

## Клиенты (контракт)

```dart
// Soft peek (не claim)
await supabase.rpc('auth_email_otp_retry_after', params: {
  'p_email': email,
  'p_max_per_hour': 3,
});

await supabase.auth.signInWithOtp(email: email, shouldCreateUser: …);
await supabase.auth.verifyOTP(email: email, token: token, type: OtpType.email);
```

- Mobile: `AuthRepository` — `otpMaxPerHour = 3`; rate-limit → `AuthFailure(emailOtpRateLimited, retryAfterSeconds)`; OTP step cooldown + resend
- Web: `OTP_MAX_PER_HOUR = 3` в `auth-api.ts`; `AuthOtpRateLimitError`; register/forgot — `AuthOtpStep` с resend/countdown

### Кейсы (оба клиента)

| Кейс | Поведение |
|------|-----------|
| Soft peek `retry_after > 0` | Не зовём `signInWithOtp`; UI показывает «Подождите m:ss» |
| Hook 429 (`Too many OTP… Retry in N seconds`) | Маппится в rate-limit; повторный peek / parse N |
| Resend на шаге OTP | Тот же send; кнопка disabled на cooldown |
| Register: email уже fully registered | `emailAlreadyRegistered` |
| Forgot: email не найден | `emailNotRegistered` |
| Неверный OTP | `otpInvalid` / verify failed |
| Verify / set password | **без** hourly send-cap (только send) |

---

## Тестирование

1. OTP на реальный inbox (письмо с `welcome@clover.com.kz`).
2. 4-я отправка на тот же email в течение часа → 429 / «Подождите…».
3. `auth_email_otp_retry_after` → seconds > 0.
4. Прямой `signInWithOtp` без soft peek всё равно бьёт в hook.
5. Web/mobile: resend на OTP-шаге уважает cooldown.

---

## Запрещено

- Resend API key / hook secret / `service_role` в git
- Grant `auth_claim_email_otp_send` на `anon` / `authenticated`
- Считать «готово» только клиентский claim без hook

---

## Связанные документы

- [../business/authentication.md](../business/authentication.md)
- [../business/email-authentication.md](../business/email-authentication.md)
- Аудит: [_backend-audit-plan.md](_backend-audit-plan.md)
- Phone: `send_sms_hook` — не смешивать с email OTP
