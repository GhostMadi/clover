# Honest quiz (temporary)

**Product:** [honest-quiz.md](../business/honest-quiz.md)  
**Migrations:** `20260912150000_honest_quiz.sql` · `20260912160000_honest_quiz_admin_site_admin.sql`  
**Временное** — не прод-фича Clover.

## Model

| | |
|--|--|
| `honest_quiz_runs` | Один проход: `client_token`, `answers` jsonb, `photo_data_url`, `finished`, `user_agent` |
| RLS | нет прямого DML; только RPC |
| `honest_quiz_upsert(...)` | anon+auth |
| `honest_quiz_admin_list()` | только `is_site_admin` |
| `honest_quiz_admin_get(p_id)` | только `is_site_admin` |

## Admin

Вход `/admin` = email+пароль + `profiles.is_site_admin`. Ответы: `/admin/honest`.
