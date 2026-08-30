# Supabase — документация бэкенда

Спеки и описания контракта. **SQL и functions** — в корне репозитория:

- миграции: [`../../supabase/migrations/`](../../supabase/migrations/)
- Edge Functions: [`../../supabase/functions/`](../../supabase/functions/)
- конфиг CLI: [`../../supabase/config.toml`](../../supabase/config.toml)

Продуктовый смысл — ссылки на [`../business/`](../business/).

---

## Спеки

| Файл | Тема |
|------|------|
| [MIGRATIONS_INDEX.md](MIGRATIONS_INDEX.md) | Навигатор по миграциям |
| [booking_backend_spec.md](booking_backend_spec.md) | Запись (booking) |
| [SPEC_BOOKING_SYSTEM.md](SPEC_BOOKING_SYSTEM.md) | Booking system |
| [SPEC_SUPABASE_SOCIAL_GRAPH_AND_ACCOUNT.md](SPEC_SUPABASE_SOCIAL_GRAPH_AND_ACCOUNT.md) | Соцграф / аккаунт |
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
