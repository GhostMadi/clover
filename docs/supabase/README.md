# Supabase — документация бэкенда

Спеки и описания контракта. **SQL и functions** — в корне репозитория:

- миграции: [`../../supabase/migrations/`](../../supabase/migrations/)
- Edge Functions: [`../../supabase/functions/`](../../supabase/functions/)
- конфиг CLI: [`../../supabase/config.toml`](../../supabase/config.toml)

Продуктовый смысл — ссылки на [`../business/`](../business/).

---

## Спеки

| Файл | Назначение |
|------|------------|
| [MIGRATIONS_INDEX.md](MIGRATIONS_INDEX.md) | Навигатор по миграциям |
| [_backend-audit-plan.md](_backend-audit-plan.md) | **План аудита бэков** (цикл / чистота / журнал) |
| Правила: **`clover-backend-feature`** (вход) · `clover-supabase-cycle` | Создание бэка фичи — всегда |
| [booking_backend_spec.md](booking_backend_spec.md) | Запись (booking) |
| [SPEC_BOOKING_SYSTEM.md](SPEC_BOOKING_SYSTEM.md) | Booking system |
| [booking-points.md](booking-points.md) | Точки хозяина + schedule settings per point |
| [SPEC_IN_APP_NOTIFICATIONS.md](SPEC_IN_APP_NOTIFICATIONS.md) | In-app уведомления (соц + запись) |
| [SPEC_POSTS_AND_EVENTS.md](SPEC_POSTS_AND_EVENTS.md) | Публикации, ивенты, enriched RPC |
| [SPEC_SUPABASE_SOCIAL_GRAPH_AND_ACCOUNT.md](SPEC_SUPABASE_SOCIAL_GRAPH_AND_ACCOUNT.md) | Соцграф / аккаунт |
| [SPEC_EMAIL_AUTH.md](SPEC_EMAIL_AUTH.md) | Email OTP: Resend SMTP, DNS clover.com.kz, Flutter |
| [SPEC_R2_DIRECT_UPLOAD.md](SPEC_R2_DIRECT_UPLOAD.md) | Cloudflare R2: presigned upload (`get-upload-url`) |
| [SPEC_ATTENDANCE_SYSTEM.md](SPEC_ATTENDANCE_SYSTEM.md) | Посещаемость (ядро: workplace / punch / membership) |
| [SPEC_RELATIONS_SYSTEM.md](SPEC_RELATIONS_SYSTEM.md) | Relations (legacy) |

Шаблон нового дока: [_template.md](_template.md)

---

## CLI (кратко)

```bash
# миграции
supabase db push

# функции (пример)
supabase functions deploy create_post
supabase functions deploy send_sms_hook
supabase functions deploy whatsapp_webhook
```

Подробнее про деплой — [`../../supabase/README.md`](../../supabase/README.md).
