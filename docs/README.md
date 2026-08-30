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
| Аутентификация | [business/authentication.md](business/authentication.md) |
| Онбординг | [business/onboarding.md](business/onboarding.md) |
| Навигация / нижний бар | [business/navigation-bars.md](business/navigation-bars.md) |
| Профиль | [business/profile.md](business/profile.md) |
| Данные профиля | [business/profile-data.md](business/profile-data.md) |
| Локализация справочников | [business/localization-dictionaries.md](business/localization-dictionaries.md) |
| Синхронизация справочников | [business/catalog-sync.md](business/catalog-sync.md) |
| Публикации и ивенты | [business/publications.md](business/publications.md) |
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
