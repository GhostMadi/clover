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
- **SELECT / UPDATE / DELETE** — нет для клиентских ролей (Dashboard / service_role / будущая админка)

## Migration

`supabase/migrations/20260908120000_support_requests.sql`
