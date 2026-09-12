# Запись: точки (места) хозяина

**Статус:** внедряется (**веб** ✅ workspace точек; **мобилка** ✅ list → hub + inbox/analytics/services/schedule по `pointId` + switcher)
**Связано с:** [booking.md](booking.md), [website-service-cache.md](website-service-cache.md), [website-host-desktop.md](website-host-desktop.md), [tag-powers.md](tag-powers.md)  
**Очередь бэка/клиентов:** [../supabase/_backend-audit-plan.md](../supabase/_backend-audit-plan.md) § Далее

---

## Зачем

У хозяина записи может быть **несколько мест** (салон / филиал / кабинет).  
UX как у посещаемости: сначала точка, потом день (inbox / услуги / расписание).

Один логин + тег `booking` = владелец. Точки — его сущности, не отдельные аккаунты.

## Участники

| Роль | Что видит |
|------|-----------|
| Хозяин | Список точек → workspace точки; last-точка в кэше |
| Мастер (staff) | Как сейчас — календарь по host-аккаунтам (отдельно) |
| Клиент | Каталог по профилю хозяина (пока все активные услуги; фильтр витрины по точке — позже) |

## Сущности

- **Точка** (`booking_points`): `id`, `host_id`, `name` (ключ не локализуем — свободное имя хозяина).
- Услуги: `booking_services.point_id` → точка.
- Записи: фильтр на сайте через `service_id` ∈ услуги точки (пока без колонки на `bookings`).

## Жизненный цикл

| Фаза | Как |
|------|-----|
| Первый вход | Нет last → `/app/settings/booking/points` (создать / выбрать) |
| Повторный | Last point → сразу `/p/[id]/inbox` (или обзор) |
| Смена | Селектор в app bar; путь `…/p/OLD/…` → `…/p/NEW/…` |
| Создать точку | Имя → default workspace |
| Удалить | Только если нет услуг (или архив позже) |

## Карта экранов (веб)

| Route | Назначение |
|-------|------------|
| `/app/settings/booking` | Entry: last → деталь; иначе points |
| `/app/settings/booking/points` | Список / создание точек |
| `/app/settings/booking/p/[pointId]` | Обзор точки |
| `…/inbox`, `…/services`, `…/analytics` | Ops точки |
| `…/settings` | Хаб настроек **этой** точки (Ещё) |
| `…/settings/schedule` | Расписание / политики точки |
| `/my`, `/calendar` | Вне точек (клиент / мастер) |

## Настройки vs точка

Как у Посещаемости: **Ещё → Настройки** — для **выбранной** сущности (точка / компания), не на все сразу.

`booking_schedule_settings.point_id` — PK; при создании точки строка настроек создаётся триггером.  
Отсутствия / blocked slots — **на точку** (`point_id`), не на весь host.

## Сознательно позже

- `point_id` на самой таблице `bookings`  
- Клиентская витрина «только эта точка»  

## Мобилка

| | |
|--|--|
| Вход | Settings → Запись = **список точек** (+ создать) |
| Hub точки | Inbox / услуги / аналитика / расписание — все с `pointId` |
| Last point | prefs `booking_last_point_<uid>` |
| Switcher в app bar | ✅ sheet выбора точки → replace route |
