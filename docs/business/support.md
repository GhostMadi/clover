# Поддержка (обращения с сайта)

**Статус:** форма на сайте → таблица в Supabase; админка позже  
**Связано с:** [website.md](website.md) · [app-store-listing.md](app-store-listing.md) · бэк: [SPEC_SUPPORT_REQUESTS.md](../supabase/SPEC_SUPPORT_REQUESTS.md)

## Зачем

Публичная точка связи для App Store / пользователей **без** входящего ящика поддержки на `welcome@…` (это отправитель OTP через Resend, не inbox).

## Как сейчас

1. Пользователь открывает https://clover.com.kz/support  
2. Заполняет контакт (ник или email) и текст проблемы  
3. Заявка пишется в `public.support_requests`  
4. Команда смотрит заявки в **Supabase Table Editor** (пока нет админки)

## Дальше

Админка на сайте: список заявок, статусы `new` → `in_progress` → `done`.

## Не путать

| | |
|--|--|
| `welcome@clover.com.kz` | **From** транзакционных писем (OTP) через Resend |
| `/support` | Куда писать о проблемах / удалении аккаунта |
