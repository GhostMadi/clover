# Блокировки пользователей

**Статус:** актуально (mobile + web UI v1)  
**Связано с:** [profile.md](profile.md), [settings.md](settings.md), [chats.md](chats.md), [notifications.md](notifications.md)  
**Техника:** [SPEC_SUPABASE_SOCIAL_GRAPH_AND_ACCOUNT.md](../supabase/SPEC_SUPABASE_SOCIAL_GRAPH_AND_ACCOUNT.md)

---

## Зачем

Пользователь может **закрыть контакт** с другим аккаунтом: не подписываться и не получать follow от него (симметричный запрет через `can_user_interact`), **сразу убрать** контент блокируемого из своей ленты/карты и **уведомить** команду Clover (App Store 1.2 — см. [ugc-safety.md](ugc-safety.md)).

---

## Участники / роли

| Роль | Что |
|------|-----|
| Владелец | Блокирует с чужого профиля; смотрит список в Настройки → Аккаунт → Заблокированные |
| Заблокированный | Не может подписаться на блокирующего (и наоборот), пока блок активен |
| Clover | RPC `block_user` (также пишет `content_reports`) / `unblock_user` / `list_my_blocked_users` |

---

## Сущности

- `profile_blocks` (blocker_id → blocked_id)
- При блоке: follow-рёбра **в обе стороны** снимаются

---

## Жизненный цикл

| Фаза | Как |
|------|-----|
| Заблокировать | Чужой профиль / чужой пост → confirm → `block_user` → report `source=block` → контент пропадает из Event/Map → выход с экрана гостя |
| Список | Настройки → Аккаунт → Заблокированные |
| Разблокировать | В списке кнопка «Разблокировать» → шторка Да/Нет → `unblock_user` |
| Тап по тайлу | Открывает guest-профиль |
| Follow при блоке | RPC `follow_user` → `user_blocked` |

---

## Карта экранов

| Где | Что |
|-----|-----|
| Guest profile (mobile + web) | ⋯ у «Назад» → «Пожаловаться» / «Заблокировать» |
| Чужой пост (mobile) | Меню → «Заблокировать» / «Пожаловаться» |
| Настройки → Аккаунт | Пункт «Заблокированные» |
| Список | Имя/аватар + «Разблокировать» |

---

## Стыки → решения

| Тема | Решение |
|------|---------|
| Скрытие постов в ленте / карте | Да: RPC фильтр `viewer_is_blocked_with` + мгновенный client hide |
| Уведомление разработчика | `content_reports` при блоке ([ugc-safety.md](ugc-safety.md)) |
| Чат | v1 блок с профиля; чат-меню — later |
| REST insert в `profile_blocks` | Предпочитать RPC (side-effect unfollow + report) |

---

## Вне скоупа

- Скрытие постов без полного блока  
- Блок из чата (позже)

---

## Связанные

- [features-catalog.md](features-catalog.md) · [profile.md](profile.md)
