# Документация Clover

Вся проектная документация — в **`docs/`**, три раздела:

| Раздел | Папка | Что внутри |
|--------|-------|------------|
| **Бизнес-процесс** | [`business/`](business/) | Как работает продукт для пользователя (не код) |
| **Правила и код** | [`code/`](code/) | Cursor rules, UI, архитектура Flutter |
| **Supabase (бэк)** | [`supabase/`](supabase/) | Спеки, миграции-index, контракт БД |

Код миграций и Edge Functions по-прежнему в корневом [`supabase/`](../supabase/) (CLI).  
Доки про бэк — в [`docs/supabase/`](supabase/).

---

## Бизнес-процесс

| Процесс | Файл |
|---------|------|
| **Чеклист новой фичи (жизненный цикл)** | [business/_feature-lifecycle-checklist.md](business/_feature-lifecycle-checklist.md) |
| Аутентификация (логин / регистрация / пароль) | [business/authentication.md](business/authentication.md) |
| Email OTP и транзакционная почта | [business/email-authentication.md](business/email-authentication.md) |
| Онбординг | [business/onboarding.md](business/onboarding.md) |
| Навигация / нижний бар | [business/navigation-bars.md](business/navigation-bars.md) |
| Профиль | [business/profile.md](business/profile.md) |
| Данные профиля | [business/profile-data.md](business/profile-data.md) |
| Локализация справочников | [business/localization-dictionaries.md](business/localization-dictionaries.md) |
| Синхронизация справочников | [business/catalog-sync.md](business/catalog-sync.md) |
| Публикации и ивенты | [business/publications.md](business/publications.md) |
| Реакции и комментарии | [business/reactions.md](business/reactions.md) · [business/comments.md](business/comments.md) |
| Фильтры ленты / карты / профиля | [business/filters.md](business/filters.md) |
| Сохранённые посты | [business/saved-posts.md](business/saved-posts.md) |
| Архивы | [business/archives.md](business/archives.md) |
| Кластеры (коллекции) | [business/clusters.md](business/clusters.md) |
| Чаты и сообщения | [business/chats.md](business/chats.md) |
| Уведомления (in-app) | [business/notifications.md](business/notifications.md) |
| Настройки приложения | [business/settings.md](business/settings.md) |
| Местоположения | [business/locations.md](business/locations.md) |
| Блокировки (бэк) | [business/blocks.md](business/blocks.md) |
| Онлайн-запись | [business/booking.md](business/booking.md) |
| Бронь мест (схема зала) | [business/venue-seating.md](business/venue-seating.md) |
| Посещаемость (геозона, смены) | [business/attendance.md](business/attendance.md) · хвосты сайта: [website-attendance-gaps.md](business/website-attendance-gaps.md) |
| Бонусы (лояльность) | [business/bonuses.md](business/bonuses.md) |
| Сайт (лендинг + legal + кабинет) | [business/website.md](business/website.md) · **дорожная карта:** [website-roadmap.md](business/website-roadmap.md) · [gap-plan](business/website-gap-plan.md) |
| Деплой сайта (Vercel / `web-production`) | [business/website-deploy.md](business/website-deploy.md) |
| Деплой мобилки (TestFlight / `mobile-production`) | [business/mobile-deploy.md](business/mobile-deploy.md) |
| Ветки Git (`main` / mobile / web) | [business/git-branches.md](business/git-branches.md) |
| App Store — privacy labels | [business/app-store-privacy-labels.md](business/app-store-privacy-labels.md) |
| Каталог фич | [business/features-catalog.md](business/features-catalog.md) |

Черновики: [business/_inbox.md](business/_inbox.md) · шаблон: [business/_template.md](business/_template.md)

---

## Правила и код

- Правила Cursor (источник): [`code/rules/`](code/rules/)
- UI / adaptive / аудит: [`code/ui/`](code/ui/)

---

## Supabase

- Индекс и спеки: [`supabase/README.md`](supabase/README.md)
- SQL-файлы: [`../supabase/migrations/`](../supabase/migrations/)

---

## Порядок работы

1. Продукт → `docs/business/`
2. Бэк → `docs/supabase/` + миграции в `supabase/migrations/`
3. Flutter → по `docs/code/rules/`
