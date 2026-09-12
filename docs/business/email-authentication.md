# Email OTP и транзакционная почта

**Статус:** ✅ в бою — домен Verified; Send Email Hook → Edge → Resend REST; лимит **3 OTP / email / час**  
**Роль в продукте:** канал для **регистрации**, **сброса пароля** и подтверждения email — **не** основной ежедневный логин  
**Целевая модель входа:** [authentication.md](authentication.md) (ник/email + пароль)  
**Техника (архитектура, процесс настройки, кейсы):** [../supabase/SPEC_EMAIL_AUTH.md](../supabase/SPEC_EMAIL_AUTH.md)

---

## Цель

Надёжная доставка OTP с **welcome@clover.com.kz** и серверный гейт: не больше **трёх** писем на один адрес за скользящий час. WhatsApp/SMS — later.

---

## Как вписывается в вход

| Сценарий | Email OTP нужен? |
|----------|------------------|
| Ежедневный вход (ник/email + пароль) | Нет |
| Регистрация по почте | Да → код → **установка пароля** |
| Забыли пароль | Да → код → **новый пароль** |
| Google / Apple | Нет (пароль опционально позже в настройках) |

Тестовый OTP-блок на экране логина — если ещё виден, убрать (регистрация/сброс — отдельные экраны).

---

## Кто участвует

| Роль | Что делает |
|------|------------|
| Пользователь | Запрашивает код, вводит код, задаёт пароль (в целевом flow) |
| Clover (Flutter / Web) | OTP + проверка кода; soft peek лимита |
| Supabase Auth + Send Email Hook | Генерация OTP, **запись лимита**, отправка через Resend HTTP |
| Resend | Доставка с домена clover.com.kz |
| UniHost | DNS (DKIM / SPF / DMARC) |

---

## Бизнес-процесс (доставка письма)

```
Клиент → Supabase Auth (OTP)
       → Send Email Auth Hook (HTTPS)
       → Edge send_email_hook (HMAC → лимит 3/час → Resend REST)
       → welcome@clover.com.kz → Inbox → код в приложении / на сайте
```

**Лимит:** один email — max 3 отправки / час (регистрация и сброс делят счётчик).  
Verify / пароль — без этого лимита. Eligibility register≠reset — отдельно (см. [authentication.md](authentication.md)).

Полный flow, шаги настройки (Resend key, Hook, secrets, deploy) и клиентские кейсы — в SPEC.

Подробный целевой UX регистрации/сброса — в [authentication.md](authentication.md).

---

## Письмо

| Элемент | Значение |
|---------|----------|
| От кого | **Clover** \<welcome@clover.com.kz\> (домен **Verified**) |
| Доставка | Inbox (DKIM / SPF / DMARC) |
| Тема | Код подтверждения / сброс пароля Clover |
| Содержимое | **6-значный OTP** (HTML в Edge hook) |

---

## Тарифы Resend

| План | Лимит |
|------|-------|
| **Free** (сейчас) | 3 000 / мес, ~100 / день |
| Pro | от $20/мес, 50 000+ |

---

## Домен

| | |
|--|--|
| clover.com.kz | UniHost |
| Resend | **Verified** |
| Отправитель | welcome@clover.com.kz |

Детали — [SPEC_EMAIL_AUTH.md](../supabase/SPEC_EMAIL_AUTH.md).

---

## Связанные процессы

- [authentication.md](authentication.md) — целевой логин / регистрация / пароль
- [settings.md](settings.md) — установить пароль после Google
- [onboarding.md](onboarding.md)
