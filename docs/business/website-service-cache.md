# Сайт: кэш синхронизации сервисов

**Статус:** внедрён (запись + посещаемость + ресурсы)  
**Связано с:** [website-host-desktop.md](website-host-desktop.md), [website-cabinet.md](website-cabinet.md), [attendance.md](attendance.md), [booking-points.md](booking-points.md), [website-gap-plan.md](website-gap-plan.md)

---

## Зачем

Начальник на сайте часто переключает день / компанию / inbox / услуги.  
Нужно: **показывать из кэша сразу**, затем тихо подтянуть бэк и обновить UI — без ощущения «пустой экран → долгая загрузка» на каждом заходе.

Punch / offline outbox — только мобилка ([website-attendance-gaps.md](website-attendance-gaps.md)).  
На сайте кэш — **read cache + UX prefs**, не замена RLS.

Паттерн: **stale-while-revalidate (SWR)** через `service-sync-cache` + `*-prefs` + опционально `run-service-swr`.

## Участники

| Роль | Что кэшируется |
|------|----------------|
| Хозяин сервиса | Снимок списков и табов, last-selected id |
| Worker | Как сейчас — read-only; prefs не для punch |

## Правила

1. Ключ scoped по `userId` + сервис (`attendance` / `booking` / `resources`).
2. Envelope: `{ v, savedAt, data }` + TTL; устаревшее — не использовать как единственный источник.
3. После успешного fetch — писать кэш; UI может стартовать из кэша (SWR).
4. Права и правда данных — всегда с бэка (RPC/RLS). Кэш не даёт «лишних» прав.
5. Теги маркеров / shortcut — по-прежнему с бэка, не из prefs-флагов shortcut.
6. Есть кэш → paint без shimmer; нет → shimmer → fetch → write.
7. Поиск / query (inbox) — кэш не читает и не пишет.

## Посещаемость

| Поверхность | Bucket | TTL |
|-------------|--------|-----|
| Компании (slim, switcher) | `admin-hub` | 7d |
| Хаб компаний (full) | `admin-hub-full` | 7d |
| Снимок компании | `workplace:{id}` | 7d |
| Сегодня | `today:{id}` (+ dayKey) | 24h |
| Работники | `members:{id}` | 24h |
| Смены / duty | `duty:{id}` | 24h |
| Аналитика / табель | `analytics:{id}:{from}:{to}` | 6h |
| Зарплата | `payroll:{id}:{from}:{to}` | 6h |
| Вход | Last workplace → `/w/[id]` | LS |

## Запись

См. [booking-points.md](booking-points.md).

| Поверхность | Bucket | TTL |
|-------------|--------|-----|
| Точки | `points` | 7d |
| Inbox / хаб | `inbox:{pointId}` | 24h |
| Услуги | `services:{pointId}` | 7d |
| Расписание | `schedule` | 24h |
| Аналитика | `analytics:{from}:{to}` | 6h |

## Ресурсы

| Поверхность | Bucket | TTL |
|-------------|--------|-----|
| Местоположения | `locations` | 7d |
| Деталь места | `location:{id}` | 7d |
| Фильтры профиля | `profile-filters` | 7d |

## Сознательно не здесь

- Offline punch / outbox  
- Полноценный IndexedDB / React Query как обязательный стек (сейчас LS envelope + event)
- Worker punch UX prefs
