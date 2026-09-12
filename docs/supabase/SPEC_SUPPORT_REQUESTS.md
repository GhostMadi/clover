# Support requests — заявки с сайта

**Продукт:** [support.md](../business/support.md)

## Table `public.support_requests`

| Column | Type | Notes |
|--------|------|--------|
| `id` | uuid PK | |
| `created_at` | timestamptz | |
| `contact` | text | ник или email для ответа |
| `message` | text | суть проблемы |
| `user_id` | uuid nullable | `auth.uid()` если залогинен |
| `source` | text | `web` \| `app` |
| `status` | text | `new` \| `in_progress` \| `done` |

## RLS

- **INSERT** — `anon` + `authenticated`  
- Rate-limit: max **5** заявок с одного `contact` за час (`20260912121000_support_requests_rate_limit.sql`)  
- **SELECT / UPDATE / DELETE** — нет для клиентских ролей (Dashboard / service_role / будущая админка)

**Сознательно позже:** админка на сайте.

## Migration

`supabase/migrations/20260908120000_support_requests.sql` · rate-limit `20260912121000_…`
