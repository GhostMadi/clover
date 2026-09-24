# UGC Safety (App Store 1.2)

**Статус:** актуально (mobile v1; web — те же RPC)  
**Связано с:** [blocks.md](blocks.md), [authentication.md](authentication.md), [publications.md](publications.md), [website-admin.md](website-admin.md)  
**Техника:** [SPEC_CONTENT_REPORTS.md](../supabase/SPEC_CONTENT_REPORTS.md)

---

## Зачем

В Clover есть пользовательский контент (посты, ивенты, профили, чаты). Нужны меры Apple Guideline **1.2**:

1. Согласие с условиями (EULA / Terms) **до** регистрации или входа  
2. Фильтрация нежелательного контента (блок скрывает из ленты / карты)  
3. Жалоба (flag) на контент или пользователя  
4. Блок пользователя: мгновенно убирает контент из ленты **и** уведомляет команду Clover  
5. Команда реагирует на жалобы **в течение 24 часов** (удаление контента / ограничение аккаунта)

---

## Участники / роли

| Роль | Что |
|------|-----|
| Гость / новый пользователь | Читает Terms + Privacy, ставит согласие, затем входит / регистрируется |
| Пользователь | Жалуется на пост или профиль; блокирует автора |
| Clover (модерация) | Смотрит `content_reports`, действует ≤ 24ч |

---

## Сущности

- Условия: https://clover.com.kz/terms (zero-tolerance к objectionable / abusive)  
- Privacy: https://clover.com.kz/privacy  
- `content_reports` — жалобы и уведомления от блока  
- `profile_blocks` — блок (см. [blocks.md](blocks.md))

---

## Жизненный цикл

| Фаза | Как |
|------|-----|
| Согласие | Чекбокс на экране входа / регистрации / соцкнопках; без галочки CTA и соцвход недоступны |
| Жалоба | Пост (чужой) или guest-профиль → «Пожаловаться» → причина (EN-ключ) → RPC `report_content` |
| Блок | Guest-профиль или пост → «Заблокировать» → confirm → RPC `block_user` (создаёт report `source=block`) → выход с экрана; посты автора пропадают из Event / Map для блокирующего |
| Модерация | Команда: open-отчёты → снять контент / eject нарушителя ≤ 24ч |

---

## Карта экранов (mobile)

| Где | Что |
|-----|-----|
| Login / Register | Чекбокс Terms + Privacy со ссылками |
| Guest profile | ⋯ рядом с «Назад» → «Пожаловаться» · «Заблокировать» |
| Чужой пост (меню) | «Пожаловаться» · «Заблокировать» |
| Настройки → Заблокированные | Список / разблок (как раньше) |

---

## Причины жалобы (ключи EN)

| Ключ | Подпись (RU, клиент) |
|------|----------------------|
| `objectionable_content` | Неприемлемый контент |
| `abusive_user` | Оскорбительное поведение |
| `spam` | Спам |
| `harassment` | Травля / угрозы |
| `other` | Другое |

---

## Стыки → решения

| Тема | Решение |
|------|---------|
| «Уведомить разработчика» при блоке | `block_user` пишет строку в `content_reports` (`source=block`) |
| Мгновенно убрать из ленты | Клиент фильтрует текущую ленту; RPC ленты/карты не отдают авторов из `profile_blocks` |
| Фильтрация objectionable | Блок + жалобы + модерация 24ч (не отдельный ML-фильтр в v1) |
| Админка UI | v1: таблица в Supabase / позже `/admin/moderation` |

---

## Правила / ограничения

- Жаловаться на себя нельзя  
- Дубликат open-жалобы на тот же пост от того же пользователя — идемпотентно (без ошибки UX)  
- Блок симметрично прячет контент в Event/Map для обеих сторон связи

---

## Вне скоупа

- Авто-модерация ML  
- Жалобы на отдельные комментарии / сообщения чата (позже)  
- Полноценный admin UI на сайте (позже)

---

## Запись для App Review

С физического устройства снять:

1. Чекбокс Terms на входе (до логина) — ссылки открывают clover.com.kz/terms и /privacy  
2. «Пожаловаться» на пост (⋯) или guest-профиль  
3. «Заблокировать» — confirm → пост пропадает из Event-ленты  

Вложить в Notes App Review Information.

### Текст ответа в ASC (можно вставить)

```
We implemented Guideline 1.2 UGC precautions in build 1.0 (45):

1) EULA / Terms of Use — users must agree via checkbox on the login and registration screens before email login, registration, Google, or Apple Sign In. Terms (https://clover.com.kz/terms) state zero tolerance for objectionable content and abusive users, and that we act on reports within 24 hours.

2) Filtering — blocking a user immediately removes their posts from the reporter’s Event feed and Map (client + server filter via profile_blocks).

3) Flag / report — users can report a post or profile (⋯ menu on posts / guest profile). Reports are stored for moderation (content_reports).

4) Block — users can block from a post or guest profile. Blocking notifies us (content_reports source=block) and instantly hides the user’s content from the blocker’s feed.

We will attach a screen recording on a physical device showing: Terms checkbox before login, Report, and Block.

Moderation commitment: we review open reports and remove offending content / restrict the offending account within 24 hours.
```

---

## Связанные

- [blocks.md](blocks.md) · [authentication.md](authentication.md) · [features-catalog.md](features-catalog.md)
