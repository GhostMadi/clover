# Honest quiz (temporary)

**Product:** [honest-quiz.md](../business/honest-quiz.md)  
**Migrations:** `20260912150000_honest_quiz.sql` · `20260912160000_honest_quiz_admin_site_admin.sql`  
**Временное** — не прод-фича Clover.

## Model

| | |
|--|--|
| `honest_quiz_runs` | Один проход: `client_token`, `answers` jsonb, `photo_data_url` (data URL, optional), `finished`, `user_agent`, timestamps |
| RLS | нет прямого DML у anon/auth; только RPC |
| `honest_quiz_upsert(...)` | anon+auth: создать/обновить свой run по `client_token` |
| `honest_quiz_admin_list()` | список runs — только `is_site_admin` |
| `honest_quiz_admin_get(p_id)` | один run с фото — только `is_site_admin` |

## answers keys (EN)

```json
{
  "q1": "yes",
  "q2": "yes",
  "q3": "send",
  "q1_no_attempts": 3,
  "q2_no_attempts": 5,
  "q3_no_attempts": 4
}
```

## Admin

Вход в `/admin` email+пароль аккаунта с `profiles.is_site_admin`.  
Ответы: `/admin/honest`. Отдельный secret env **не нужен**.
