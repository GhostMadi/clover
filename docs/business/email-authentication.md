# Email OTP и транзакционная почта

**Статус:** домен **Verified** в Resend; SMTP продакшн-готов  
**Роль в продукте:** канал для **регистрации**, **сброса пароля** и подтверждения email — **не** основной ежедневный логин  
**Целевая модель входа:** [authentication.md](authentication.md) (ник/email + пароль)  
**Техника (SMTP, DNS, шаблоны):** [../supabase/SPEC_EMAIL_AUTH.md](../supabase/SPEC_EMAIL_AUTH.md)

---

## Цель

Надёжная доставка писем Clover с **welcome@clover.com.kz** (OTP-коды, восстановление пароля) во «Входящие», без лимита встроенного SMTP Supabase.

---

## Как вписывается в вход

| Сценарий | Email OTP нужен? |
|----------|------------------|
| Ежедневный вход (ник/email + пароль) | Нет |
| Регистрация по почте | Да → код → **установка пароля** |
| Забыли пароль | Да → код → **новый пароль** |
| Google / Apple | Нет (пароль опционально позже в настройках) |

Тестовый блок OTP на текущем экране логина — временный; убирается, когда появится полноценная регистрация/сброс.

---

## Кто участвует

| Роль | Что делает |
|------|------------|
| Пользователь | Запрашивает код, вводит код, задаёт пароль (в целевом flow) |
| Clover (Flutter) | OTP + проверка кода (+ установка пароля в целевом UX) |
| Supabase Auth | OTP, сессия, шаблоны |
| Resend | Custom SMTP, домен clover.com.kz |
| UniHost | DNS (DKIM / SPF / DMARC) |

---

## Бизнес-процесс (доставка письма)

```
Flutter → Supabase Auth (OTP) → Resend (welcome@clover.com.kz)
    → DNS clover.com.kz → Inbox → код в приложении
```

Подробный целевой UX регистрации/сброса — в [authentication.md](authentication.md).

---

## Письмо

| Элемент | Значение |
|---------|----------|
| От кого | **Clover** \<welcome@clover.com.kz\> (домен **Verified**) |
| Доставка | Inbox (DKIM / SPF / DMARC) |
| Тема | Ссылка для входа / Код подтверждения Clover |
| Содержимое | Логотип + **6-значный OTP** |

---

## Тарифы Resend

| План | Лимит |
|------|-------|
| **Free** (сейчас) | 3 000 / мес, ~100 / день |
| Pro | от $20/мес, 50 000+ |

Встроенный SMTP Supabase без Custom SMTP — не использовать (~2 письма/час).

---

## Домен

| | |
|--|--|
| clover.com.kz | UniHost |
| Resend | **Verified** |
| Отправитель | welcome@clover.com.kz |

Детали DNS — [SPEC_EMAIL_AUTH.md](../supabase/SPEC_EMAIL_AUTH.md).

---

## Связанные процессы

- [authentication.md](authentication.md) — целевой логин / регистрация / пароль
- [settings.md](settings.md) — установить пароль после Google
- [onboarding.md](onboarding.md)
