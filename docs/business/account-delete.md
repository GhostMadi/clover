# Удаление / деактивация аккаунта

**Статус:** актуально (App Store 5.1.1(v))  
**Связано с:** [settings.md](settings.md) · [account-sleep.md](account-sleep.md) · [authentication.md](authentication.md) · [app-store-listing.md](app-store-listing.md)  
**Техника:** RPC `soft_delete_account` · Edge `delete_account` (только soft-hide, **без** Auth Admin wipe) · hard wipe — вручную через support

---

## Зачем

Два разных действия для сторов и пользователя:

1. **Деактивировать** (in-app / сайт) — скрыть витрину и выйти, **без** каскадного wipe.  
2. **Безвозвратное удаление** — запрос через `/support` / `/delete-account`, обработка командой (обычно ≤ 30 дней).

Копирайт UI **не** обещает «безвозвратное стирание» на кнопке деактивации.

---

## Участники / роли

| Роль | Что |
|------|-----|
| Владелец | Настройки → Аккаунт → «Деактивировать аккаунт» → confirm → soft-hide → выход |
| Владелец (hard) | `/delete-account` §2 → `/support` с текстом «Безвозвратное удаление аккаунта» |
| Support | Подтверждает владельца, удаляет / обезличивает данные; Auth wipe — вручную вне приложения |

---

## Жизненный цикл

### Деактивация (soft)

| Фаза | Как |
|------|-----|
| Confirm | Sheet: скрытие как при сне; указание hard-path на clover.com.kz/delete-account |
| Soft-hide | RPC `soft_delete_account` → `account_state = hibernate`, `content_visible = false` (без лимита 30 дней) |
| После | Локальный wipe сессии → login |
| Снова войти | `wake_up_if_needed` пробуждает, как после сна |

### Безвозвратное удаление (hard)

| Фаза | Как |
|------|-----|
| Запрос | Форма `/support` + ник/email |
| SLA | Обычно до 30 дней |
| Результат | Удаление / обезличивание профиля, контента (где возможно), сессий, push-токенов |

---

## Сон vs деактивация vs hard

| | Сон | Деактивировать (in-app) | Hard (support) |
|--|-----|-------------------------|----------------|
| Видимость | скрыт | скрыт (тот же state) | аккаунт снят / обезличен |
| Лимит 30 дней на повтор | да | нет | — |
| Каскад / deleteUser | нет | нет | да (вручную) |
| Пробуждение при входе | да | да | нет (аккаунта нет) |

---

## Карта экранов

| Где | Что |
|-----|-----|
| Настройки → Аккаунт (mobile + web) | «Деактивировать аккаунт» + confirm с hard-path |
| `/delete-account` | §1 soft · §2 hard через support |

---

## Вне скоупа (пока)

- `auth.admin.deleteUser` из приложения
- Отдельный `account_state = deleted`
- Self-serve hard wipe без поддержки

---

## Связанные

- [account-sleep.md](account-sleep.md) · [settings.md](settings.md) · [features-catalog.md](features-catalog.md) · marketing `/delete-account`
