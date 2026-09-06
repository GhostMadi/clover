# Сайт Clover (web)

**Статус:** лендинг + legal  
**Связано с:** мобильное приложение, App Store / TestFlight

---

## Зачем

Публичная точка входа и legal для магазинов. Продуктовая идея лендинга:

**Clover — помощник для бизнеса:** набор сервисов в одном приложении (маркетинг / посты+ресурсы, запись, посещаемость).  
В планах: **бронь мест по схеме зала** ([venue-seating.md](venue-seating.md)), фильтр мест/товаров, остатки → влияние на посты.  
**Пока бесплатно** — на лендинге без «тарифов» и давления на оплату. Тон — для широкой публики.

Цвета сервисов на сайте = акценты мобилки (жёлтый запись, синий посещаемость, сирень ресурсы, зелёный бренд).

## Участники / роли

- Гость сайта — читает лендинг и legal
- Пользователь приложения — переходит по ссылкам из стора / настроек
- Команда Clover — обновляет тексты и деплоит `web/`

## Фазы

| Фаза | Как |
|------|-----|
| Сейчас | лендинг + legal (в футере) + auth (`/auth`) + кабинет 3 таба (`/app`) |
| Дальше | лента/чаты с бэка, сервисы бизнеса в веб |
| Не сейчас | дублировать бизнес-логику мобилки на клиенте сайта |

Кабинет: [website-cabinet.md](website-cabinet.md).  
План догона мобилки: [website-gap-plan.md](website-gap-plan.md).

### Auth (web)

Те же методы, что мобилка: ник/email+пароль (`auth_resolve_login_email`), регистрация/сброс email OTP, Google OAuth (на вебе — redirect, в приложении — native idToken).  
Env: `web/.env.local` → `NEXT_PUBLIC_SUPABASE_*`.

**Google Web client** («Clover Web Client»):

| Поле | Значение |
|------|----------|
| JS origins | `http://localhost:3000`, `https://clover.com.kz` |
| Redirect URI | `https://wewrosbaxhkukbefjwzf.supabase.co/auth/v1/callback` |
| Client ID / Secret | только в **Supabase → Auth → Providers → Google** |
| Redirect сайта | Supabase URL config: `…/auth/callback` для localhost и clover.com.kz |

`client_secret*.json` не в репо и не в `NEXT_PUBLIC_*` — сайт ходит в Google через Supabase.

## Правила

- Стек сайта: Next.js / React / TypeScript
- Бренд: зелёный Clover (`#8BC34A`), не generic purple template
- Юр. тексты — черновик; перед продом сверить с юристом / фактами обработки данных
- Код сайта только в `web/`, продукт/процесс — здесь и в соседних business-доках

## Деплой на домен

Официальный домен: **clover.com.kz** (уже UniHost + почта Resend).  
Инструкция: [website-deploy.md](website-deploy.md).

Чтобы сайт открылся в интернете, нужны твои разрешения:
1. логин / доступ к **Vercel** (деплой `web/`);
2. доступ к **UniHost DNS** — добавить записи для сайта, **не ломая** почту.


Веб ведёт Cursor по `.cursor/rules/clover-web-*.mdc` (порядок docs → бэк → код, пакеты, дизайн, RLS).

| Правило | О чём |
|---------|--------|
| `clover-web-overview` | режим «агент ведёт», версии, границы репо |
| `clover-web-architecture` | папки App Router / components / features |
| `clover-web-stack` | какие npm ставить |
| `clover-web-design` | бренд и токены |
| `clover-web-resources` | переиспользование UI / Resources First для веба |
| `clover-web-harmony` | связь с Supabase как у мобилки |
| `clover-web-checklist` | чеклист перед «готово» |

## Где код

`web/` в корне репозитория Clover.
