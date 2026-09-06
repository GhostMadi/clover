# Деплой сайта clover.com.kz

Домен уже куплен и используется для почты (Resend / UniHost). Сайт вешаем на **тот же** `clover.com.kz`.

## В коде

Канонический URL: `web/src/lib/site.ts` → `https://clover.com.kz`.

## Что нужно от тебя (разрешения)

1. **Vercel** (или другой хостинг) — аккаунт, куда задеплоить `web/`
   - либо залогинь Cursor/агента в Vercel CLI: `npx vercel login`
   - либо создай проект вручную и дай доступ
2. **UniHost DNS** — право менять записи зоны `clover.com.kz`
   - **не трогать** существующие MX / SPF / DKIM для Resend (почта `welcome@…`)
   - добавить только A / CNAME для сайта, как скажет Vercel

## Шаги (когда дашь доступ)

1. `cd web && npx vercel` → привязать GitHub `GhostMadi/clover`, Root Directory = `web`
2. В Vercel → Domains → добавить `clover.com.kz` (+ `www` → redirect)
3. В UniHost вставить DNS из Vercel (обычно):
   - `A` `@` → IP Vercel **или**
   - `CNAME` `www` → `cname.vercel-dns.com`
4. Дождаться TLS (минуты–часы)
5. Проверить: https://clover.com.kz , `/privacy`, `/terms`

## Важно

Почта на домене уже работает — при смене DNS не удаляй записи Resend из `docs/supabase/SPEC_EMAIL_AUTH.md`.
