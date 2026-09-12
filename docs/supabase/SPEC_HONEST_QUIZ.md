# Honest quiz (temporary)

**Product:** [honest-quiz.md](../business/honest-quiz.md)  
**Migration:** `20260912150000_honest_quiz.sql`  
**Временное** — не прод-фича Clover.

## Model

| | |
|--|--|
| `honest_quiz_runs` | Один проход: `client_token`, `answers` jsonb, `photo_data_url` (data URL, optional), `finished`, `user_agent`, timestamps |
| RLS | нет прямого DML у anon/auth; только RPC |
| `honest_quiz_upsert(...)` | anon+auth: создать/обновить свой run по `client_token` |
| `honest_quiz_admin_list(p_secret)` | список runs, если секрет совпал |
| `honest_quiz_admin_get(p_secret, p_id)` | один run с фото |

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

## Admin secret

Сравнивается в RPC с константой + на вебе `HONEST_QUIZ_ADMIN_SECRET`.  
Дефолт в миграции задокументирован; сменить оба места перед шарингом ссылки админки.
