# Сон аккаунта (hibernate)

**Статус:** актуально  
**Связано с:** [settings.md](settings.md) · [authentication.md](authentication.md) · [features-catalog.md](features-catalog.md)  
**Техника:** [SPEC_SUPABASE_SOCIAL_GRAPH_AND_ACCOUNT.md](../supabase/SPEC_SUPABASE_SOCIAL_GRAPH_AND_ACCOUNT.md) §4.7–4.8

---

## Зачем

Пользователь может **временно скрыть** витрину и контент из лент/поиска гостей, не уничтожая аккаунт и граф подписок.  
Это **не** удаление и **не** сброс контента.

---

## Участники / роли

| Роль | Что |
|------|-----|
| Владелец аккаунта | Включает сон из Настройки → Аккаунт; просыпается при следующем входе |
| Гости / лента | Не видят посты/профиль спящего (как сейчас на бэке) |
| Support | Soft «деактивация» in-app ([account-delete.md](account-delete.md)) или legal `/delete-account`; hard wipe Auth — через support, не из приложения |

---

## Сущности

- `profiles.account_state`: `active` \| `hibernate`
- `content_visible`, `last_hibernate_at` (лимит **1 сон / 30 дней**)

---

## Жизненный цикл

| Фаза | Как |
|------|-----|
| Действовать (сон) | Подтверждение → `hibernate_account()` → sign-out |
| Проснуться | После login / session restore → `wake_up_if_needed()` (идемпотентно) |
| Лимит | Повторный сон раньше 30 дней → ошибка `hibernate_rate_limited` |
| Сброс контента | **Не делаем** (`reset_account` отключён) |
| Hard delete | Soft in-app: [account-delete.md](account-delete.md); без сессии — `/delete-account` / support. Cascade wipe Auth — вне скоупа приложения |

---

## Карта экранов

| Где | Что |
|-----|-----|
| Настройки → Аккаунт (mobile + web) | Пункт «Усыпить аккаунт» + confirm sheet |
| После входа | Silent `wake_up_if_needed` |

Копирайт: **сон ≠ удаление**. In-app «Деактивировать» тоже soft; безвозвратное удаление — `/delete-account` §2.

---

## Стыки → решения

| Тема | Решение |
|------|---------|
| «Удалить» на вебе | ✅ Переименовано в «Усыпить аккаунт» (сон ≠ wipe) |
| Wake | ✅ `wake_up_if_needed` после login / OAuth callback / `reportAccountLogin` |
| Reset wipe | Вне скоупа (остаётся disabled) |

---

## Вне скоупа

- Полный wipe контента (`reset_account`) без удаления auth-user
- Hard wipe `auth.users` из приложения
- Phone OTP (отложено)

---

## Связанные

- [settings.md](settings.md) · [authentication.md](authentication.md) · [account-delete.md](account-delete.md) · marketing `/delete-account`
