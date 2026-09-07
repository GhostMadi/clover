# Деплой сайта clover.com.kz

Домен уже куплен и используется для почты (Resend / UniHost). Сайт вешаем на **тот же** `clover.com.kz`.

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

## DNS (UniHost)

1. В Vercel → Project → Domains → `clover.com.kz` (+ `www`)
2. В UniHost добавить **только** A/CNAME, которые покажет Vercel
3. **Не трогать** MX / SPF / DKIM для Resend (почта `welcome@…`)

## Проверка после деплоя

- https://clover.com.kz
- `/privacy`, `/terms`
- вход `/auth`, кабинет `/app` (с теми же Supabase ключами)

## Важно

Почта на домене уже работает — при смене DNS не удаляй записи Resend из `docs/supabase/SPEC_EMAIL_AUTH.md`.
