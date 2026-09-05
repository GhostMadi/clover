# Email Auth: Custom SMTP (Resend) + OTP

**Продукт:** [../business/email-authentication.md](../business/email-authentication.md)  
**Клиент:** `lib/core/auth/`, `lib/feature/auth/login/`  
**Секреты:** API Key Resend — только в Supabase Dashboard / secrets, **не в репозитории**

---

## Цель

Транзакционные письма Clover (OTP, magic link) с **clover.com.kz** через **Resend**, без лимита встроенного SMTP Supabase.

---

## Архитектура

| Компонент | Роль |
|-----------|------|
| **Supabase Auth** | `signInWithOtp`, `verifyOTP`, сессия, шаблоны писем |
| **Resend** | Custom SMTP, доставка, репутация отправителя |
| **UniHost** | DNS зона `clover.com.kz` |
| **Flutter** | `supabase_flutter` → `AuthRepository.sendEmailOtp` / `verifyEmailOtp` |

```
Flutter → Supabase Auth → Resend SMTP → MX получателя
                ↑
         Email Templates (HTML + {{ .Token }})
```

---

## Тариф Resend (ориентир)

| | Free Tier | Pro |
|--|-----------|-----|
| Объём | 3 000 / мес, ~100 / день | 50 000+ / мес |
| Стоимость | $0 | от $20 / мес |

Лимит встроенного Supabase SMTP без Custom SMTP: **~2 письма / час** на проект.

---

## Домен (Resend)

| | |
|--|--|
| Домен | `clover.com.kz` |
| Статус | **Verified** (DKIM, SPF, return-path подтверждены) |
| Отправитель | `welcome@clover.com.kz` |
| Ограничение sandbox | **снято** — OTP на любой email получателя |

---

## DNS (UniHost, clover.com.kz)

Записи для верификации домена в Resend и доставляемости (Gmail, Mail.ru, Yandex).

### DKIM

| | |
|--|--|
| Type | TXT |
| Name | `resend._domainkey` |
| FQDN | `resend._domainkey.clover.com.kz` |
| Value | Публичный ключ из панели Resend (см. Resend → Domains → clover.com.kz) |

> В репозитории **не храним** полный ключ — только в DNS и в Resend.

### SPF / Return-Path

| Name | Type | Value |
|------|------|-------|
| `rsend` | CNAME | `rsend-euw1.forge.rmta.net` |
| `send` | CNAME | `send.forge.rmta.net` |

### DMARC

| | |
|--|--|
| Type | TXT |
| Name | `_dmarc` |
| Value | `v=DMARC1; p=none;` |

`p=none` — стартовая политика; позже можно ужесточить после стабильной доставки.

---

## Supabase: Custom SMTP

**Authentication → Emails → SMTP Settings**

| Поле | Значение |
|------|----------|
| Enable Custom SMTP | ON |
| Sender email | `welcome@clover.com.kz` |
| Sender name | `Clover` |
| Host | `smtp.resend.com` |
| Port | `465` (SSL) или `587` (TLS) |
| User | `resend` |
| Password | Resend API Key (`re_…`) — **только в Dashboard** |

---

## Supabase: Email Templates

**Authentication → Emails → Templates** (Magic Link / Confirm signup — в зависимости от типа OTP)

- **Subject:** Ссылка для входа в Clover / Код подтверждения Clover
- **Body:** HTML с логотипом (Supabase Storage public URL), блок **`{{ .Token }}`** — 6-значный OTP
- OTP length / expiry — в Authentication → Providers → Email

---

## Правила OTP

| Сценарий | Кому шлём код |
|----------|----------------|
| Регистрация | Только если email **не** завершённый аккаунт (`auth_is_email_fully_registered` = false). Незавершённый OTP-signup может переотправить код |
| Сброс пароля | Только если email **уже есть** (`auth_is_email_registered` = true) |
| Ежедневный логин | OTP **не** используется |
| Кулдаун | Не чаще 400с на email (`auth_claim_email_otp_send`) |

RPC: `auth_is_email_registered`, `auth_resolve_login_email` — `20260831100000_auth_login_helpers.sql`.  
RPC: `auth_current_user_has_password` — `20260831120000_auth_current_user_has_password.sql` (Настройки: установить vs сбросить).  
RPC: `auth_claim_email_otp_send` / `auth_email_otp_retry_after` — `20260831130000_auth_email_otp_cooldown.sql` (переотправка OTP не чаще чем раз в 400с; клиент синхронизирует локальный кэш).  
RPC: `auth_is_email_fully_registered` — `20260831140000` + `20260831150000` (`clover_password_set` / OAuth; OTP create больше не считается «занято»).

---

## Flutter (контракт)

```dart
// 1. Отправка кода
await supabase.auth.signInWithOtp(
  email: email,
  shouldCreateUser: true,
);

// 2. Проверка
await supabase.auth.verifyOTP(
  email: email,
  token: token,
  type: OtpType.email,
);
```

Реализация:

- `lib/core/auth/repositories/auth_repository.dart` — `sendEmailOtp`, `verifyEmailOtp`
- `lib/core/auth/cubit/auth_cubit.dart`
- `lib/feature/auth/login/presentation/page/login_page.dart` — тестовый блок UI

Состояния: `AuthEmailOtpSent`, ошибки `AuthErrorCode.emailOtp*`.

---

## Тестирование

1. Любой реальный inbox (Gmail, Mail.ru, Yandex) — письмо с **welcome@clover.com.kz**, бренд + OTP.
2. **Supabase → Authentication → Logs** — ошибки SMTP / rate limit.
3. Inbox + при необходимости Spam; в «Показать оригинал» — DKIM/SPF pass.
4. Не спамить «Отправить код» — лимит Free Tier Resend (3 000/мес).

---

## Запрещено в доке / коде

- API Key Resend в git
- `service_role` в клиенте
- Ожидание доставки через встроенный Supabase SMTP в продакшене

---

## Связанные документы

- [../business/authentication.md](../business/authentication.md)
- [../business/email-authentication.md](../business/email-authentication.md)
- Edge Functions SMS (отдельно): `send_sms_hook` — не смешивать с email OTP
