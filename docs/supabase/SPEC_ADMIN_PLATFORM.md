# Site admin — platform stats & ops API

**Продукт:** [website-admin.md](../business/website-admin.md)  
**Миграция:** `20260913102000_admin_platform_stats.sql`

## Gate

Браузер → `/api/admin/*` проверяет cookie `clover_admin_session` + `profiles.is_site_admin` по email.  
Дальше запросы с **service_role** (не anon).

## RPC `admin_platform_stats(p_days int default 7)`

- `SECURITY DEFINER`, execute только **`service_role`**
- `p_days` ∈ {1, 7, 30}
- Ответ jsonb, ключи EN (см. business doc)

## Support admin

Прямой DML `support_requests` через service_role из `/api/admin/support` (select + update status).  
Клиентские роли по-прежнему без SELECT/UPDATE.

## Honest quiz

`/api/admin/honest-quiz` тоже через service_role → существующие `honest_quiz_admin_*` обновлены: пропускают вызов, если `auth.role() = 'service_role'`.
