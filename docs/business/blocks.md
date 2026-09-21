# Блокировки пользователей

**Статус:** актуально (mobile + web UI v1)  
**Связано с:** [profile.md](profile.md), [settings.md](settings.md), [chats.md](chats.md), [notifications.md](notifications.md)  
**Техника:** [SPEC_SUPABASE_SOCIAL_GRAPH_AND_ACCOUNT.md](../supabase/SPEC_SUPABASE_SOCIAL_GRAPH_AND_ACCOUNT.md)

---

## Зачем

Пользователь может **закрыть контакт** с другим аккаунтом: не подписываться и не получать follow от него (симметричный запрет через `can_user_interact`).

---

## Участники / роли

| Роль | Что |
|------|-----|
| Владелец | Блокирует с чужого профиля; смотрит список в Настройки → Аккаунт → Заблокированные |
| Заблокированный | Не может подписаться на блокирующего (и наоборот), пока блок активен |
| Clover | RPC `block_user` / `unblock_user` / `list_my_blocked_users` |

---

## Сущности

- `profile_blocks` (blocker_id → blocked_id)
- При блоке: follow-рёбра **в обе стороны** снимаются

---

## Жизненный цикл

| Фаза | Как |
|------|-----|
| Заблокировать | Чужой профиль → confirm → `block_user` → выход с экрана гостя |
| Список | Настройки → Аккаунт → Заблокированные |
| Разблокировать | В списке → `unblock_user` |
| Follow при блоке | RPC `follow_user` → `user_blocked` |

---

## Карта экранов

| Где | Что |
|-----|-----|
| Guest profile (mobile + web) | «Заблокировать» + confirm |
| Настройки → Аккаунт | Пункт «Заблокированные» |
| Список | Имя/аватар + «Разблокировать» |

---

## Стыки → решения

| Тема | Решение |
|------|---------|
| Скрытие постов в ленте | v1 **нет** — только запрет follow / interact |
| Чат | v1 блок с профиля; чат-меню — later |
| REST insert в `profile_blocks` | Предпочитать RPC (side-effect unfollow) |

---

## Вне скоупа

- Жалобы / модерация  
- Скрытие постов без полного блока  
- Блок из чата (позже)

---

## Связанные

- [features-catalog.md](features-catalog.md) · [profile.md](profile.md)
