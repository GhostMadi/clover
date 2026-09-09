# Деплой сайта clover.com.kz

Домен куплен у **Unihost.kz**; DNS-зона — в **Cloudflare**; сайт — на **Vercel**.  
Почта (Resend / `welcome@`) идёт через DNS-записи в Cloudflare — **не ломать** MX/SPF/DKIM.

Карта стека: [tech-stack.md](tech-stack.md).

## В коде

- Канонический URL: `web/src/lib/site.ts` → `https://clover.com.kz`
- Vercel **Root Directory** = `web`
- Правило агента: `.cursor/rules/clover-web-deploy.mdc`

## Git → Vercel

| Ветка | Деплой |
|-------|--------|
| **`web-production`** | Production-ready веб → `clover.com.kz` (целевая ветка) |
| **`feature/*` / `fix/*`** | Черновики / Preview (если настроено) |
| **`main`** | Не пушить веб-прод напрямую без явной просьбы |

В Vercel: **Production Branch** = `web-production`.  
Правила агента: `.cursor/rules/clover-web-git.mdc`, `.cursor/rules/clover-web-deploy.mdc`.

```bash
git checkout web-production
git add …   # без .env
git commit -m "feat(web): …"
git push origin web-production
```

## Env в Vercel (Production / Preview)

Имена **с** `NEXT_PUBLIC_` (как в `web/.env.local` и в коде):

| Key | Пример значения |
|-----|-----------------|
| `NEXT_PUBLIC_SUPABASE_URL` | URL проекта Supabase |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | anon / publishable key |
| `NEXT_PUBLIC_SITE_URL` | `https://clover.com.kz` (на проде) |
| `NEXT_PUBLIC_YANDEX_MAPS_API_KEY` | ключ JS API Яндекс.Карт |

Короткие имена без префикса (`SUPABASE_URL` и т.п.) в клиент Next.js **не** подхватятся — не использовать в Vercel, если код читает `NEXT_PUBLIC_*`.

### Админка сайта (только сервер, без `NEXT_PUBLIC_`)

См. [website-admin.md](website-admin.md). Значения **не** коммитить.

| Key | Назначение |
|-----|------------|
| `ADMIN_EMAIL` | Email входа в `/admin` |
| `ADMIN_PASSWORD` | Пароль входа |
| `ADMIN_SESSION_SECRET` | Длинный случайный секрет подписи cookie сессии |

Локально: `web/.env.local`. На проде — Vercel → Environment Variables (Production).

## DNS

| Роль | Кто |
|------|-----|
| Регистратор | Unihost.kz |
| NS | Cloudflare: `cruz.ns.cloudflare.com`, `gabe.ns.cloudflare.com` |
| Сайт | записи на Vercel **в зоне Cloudflare** |
| Медиа | после Active: R2 Custom Domain `media.clover.com.kz` |

1. Vercel → Domains → `clover.com.kz` (+ `www`) — добавить/проверить записи **в Cloudflare DNS**.  
2. **Не удалять** MX / SPF / DKIM для Resend.  
3. Медиа: см. чеклист в [tech-stack.md](tech-stack.md).

## Проверка после деплоя

- https://clover.com.kz
- `/privacy`, `/terms`
- вход `/auth`, кабинет `/app` (с теми же Supabase ключами)
- админка `/admin` (после env `ADMIN_*`)
- после R2 Custom Domain: объект открывается с `https://media.clover.com.kz/…`

## Важно

Почта на домене уже работала до смены NS — после пропагации проверить OTP с `welcome@clover.com.kz`. Детали SMTP: `docs/supabase/SPEC_EMAIL_AUTH.md`.
