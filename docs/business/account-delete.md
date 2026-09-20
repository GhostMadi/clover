# Удаление аккаунта (soft, как сон)

**Статус:** актуально  
**Связано с:** [settings.md](settings.md) · [account-sleep.md](account-sleep.md) · [authentication.md](authentication.md)  
**Техника:** RPC `soft_delete_account` · Edge `delete_account` (только soft-hide, **без** Auth Admin wipe)

---

## Зачем

In-app «Удалить аккаунт» для сторов и настроек: **скрыть** витрину и выйти — **без каскадного wipe** и без `auth.admin.deleteUser`.

По данным это **тот же класс действия, что сон** ([account-sleep.md](account-sleep.md)): профиль/контент не видны в лентах, строки в БД остаются.

---

## Участники / роли

| Роль | Что |
|------|-----|
| Владелец | Настройки → Аккаунт → «Удалить аккаунт» → confirm → soft-hide → выход |
| Support | Запросы без сессии с `/delete-account` / `/support` (ручная помощь) |

---

## Жизненный цикл

| Фаза | Как |
|------|-----|
| Confirm | Sheet: скрытие как при сне, данные не стираются каскадом |
| Soft-hide | RPC `soft_delete_account` → `account_state = hibernate`, `content_visible = false` (без лимита 30 дней) |
| После | Локальный wipe сессии → login |
| Снова войти | `wake_up_if_needed` пробуждает, как после сна |
| Hard wipe Auth user | **Вне скоупа** in-app (не делаем) |

---

## Сон vs «удаление»

| | Сон | Удалить (in-app) |
|--|-----|------------------|
| Видимость | скрыт | скрыт (тот же state) |
| Лимит 30 дней | да | нет |
| Каскад / deleteUser | нет | нет |
| Пробуждение при входе | да | да |

Копирайт в UI: не обещать «безвозвратное стирание всех данных», если делаем soft.

---

## Карта экранов

| Где | Что |
|-----|-----|
| Настройки → Аккаунт | «Удалить аккаунт» + confirm |
| `/delete-account` | In-app soft путь + support fallback |

---

## Вне скоупа

- `auth.admin.deleteUser` и cascade wipe из приложения
- Отдельный `account_state = deleted` (пока хватает `hibernate`)
- Отложенное удаление 30 дней

---

## Связанные

- [account-sleep.md](account-sleep.md) · [settings.md](settings.md) · [features-catalog.md](features-catalog.md)
