# SPEC: space_plans + bind к Записи

**Статус:** черновик контракта (процесс + ТЗ готовы; миграций ещё нет)  
**Процесс:** [space-plan-resources.md](../business/space-plan-resources.md) · [space-plan-emoji-pricing.md](../business/space-plan-emoji-pricing.md)  
**ТЗ работ:** [space-plan-tz.md](../business/space-plan-tz.md)  
**Ядро записи:** [SPEC_BOOKING_SYSTEM.md](SPEC_BOOKING_SYSTEM.md)

Не дублировать продукт здесь — только таблицы, RLS, RPC, ключи EN.

---

## Цель

1. Хранить **геометрию** схемы как ресурс владельца (`space_plans`).  
2. Дать точке Записи опц. ссылку `space_plan_id`.  
3. Хранить **bind** emoji-node → услуга (± staff) на точке, не в JSON схемы.  
4. Гость читает published plan + binds; create booking — существующий поток.

Venue inventory / attendance — **вне** этой спеки v1 (тот же `space_plans`, другие таблицы позже).

---

## Таблицы (v1)

### `public.space_plans`

| Колонка | Тип | Смысл |
|---------|-----|--------|
| `id` | uuid PK | |
| `owner_id` | uuid → auth.users | Автор ресурса |
| `title` | text | Свободное имя хозяина |
| `status` | text | EN: `draft` \| `published` \| `archived` |
| `plan_json` | jsonb | Геометрия (floors/nodes) — контракт [venue-plan-json.md](../business/venue-plan-json.md) |
| `version` | int | ++ при publish |
| `created_at` / `updated_at` | timestamptz | |

Индексы: `(owner_id, status)`, `(owner_id, updated_at desc)`.

Check: `status in ('draft','published','archived')`.

### `public.booking_points` (дельта)

| Колонка | Тип | Смысл |
|---------|-----|--------|
| `space_plan_id` | uuid null → space_plans | Опц. схема витрины |

FK ON DELETE **RESTRICT** (или триггер «нельзя, пока ссылаются»).

### `public.booking_space_emoji_binds`

| Колонка | Тип | Смысл |
|---------|-----|--------|
| `id` | uuid PK | |
| `point_id` | uuid → booking_points | |
| `node_id` | text | id узла в plan_json |
| `service_id` | uuid → booking_services | |
| `staff_id` | uuid null → booking_staff | Опц. |
| `created_at` / `updated_at` | timestamptz | |

UK: `(point_id, node_id)`.  
Check: service принадлежит тому же host/point; staff (если есть) связан с service.

---

## RLS / grants (принцип)

| Кто | space_plans | binds | point.space_plan_id |
|-----|-------------|-------|---------------------|
| Owner ресурса | CRUD свои | — | — |
| Host точки | SELECT published (свои + при bind) | CRUD своих binds | UPDATE своей точки |
| Guest (authenticated) | SELECT **published** схем, на которые ссылается видимая точка витрины | SELECT binds этой точки | SELECT |
| Anon | нет (v1) | нет | нет |

Писать геометрию / binds **не** через «открытый» PostgREST без тех же проверок, что в RPC. Предпочтительно: revoke DML у `authenticated` на binds/plan_json update → только SECURITY DEFINER RPC с гейтом тега/`host_id`.

Гейт UI: тег `resources` для хаба схем; тег `booking` для точки — **дополнительно** к RLS, не вместо.

---

## RPC (ориентир имён)

| RPC | Зачем |
|-----|--------|
| `list_my_space_plans` | Хаб Ресурсов автора |
| `get_space_plan(id)` | Editor / viewer (owner: любой status; guest: published + ACL) |
| `upsert_space_plan` / `publish_space_plan` / `archive_space_plan` | Owner |
| `delete_space_plan` | Owner; fail если есть FK ссылки |
| `booking_point_set_space_plan(point_id, space_plan_id?)` | Host; plan must be owned+published или null |
| `list_booking_space_binds(point_id)` | Host + guest витрины |
| `upsert_booking_space_binds(point_id, binds[])` | Host bulk |
| `delete_booking_space_bind(point_id, node_id)` | Host |

Create booking — **существующий** RPC; опционально принять `space_node_id` → в `client_notes` или later колонка (вне must-have v1).

Ответы RPC — EN-ключи статусов; подписи на клиенте.

---

## JSON `plan_json` (граница)

В ресурсе:

- floors, nodes, frame, kind, role (`bookable`|`decor`), emoji label, groupId, zIndex, …

**Не** хранить в ресурсе:

- `service_id` / `staff_id` / цены Записи  
- inventory Брони / occasion  

Связь Записи = таблица binds. Связь Брони later = свои таблицы на `venue` + `bookable_id`.

---

## Миграции (когда делать)

Одна или две timestamp-миграции в `supabase/migrations/`:

1. `…_space_plans.sql` — таблица + RLS/RPC ресурса  
2. `…_booking_space_plan_bind.sql` — колонка на points + binds + RPC  

Строка в [MIGRATIONS_INDEX.md](MIGRATIONS_INDEX.md) обязательна после apply.

---

## Клиенты

| Клиент | Читает | Пишет |
|--------|--------|-------|
| Web Resources editor | get/upsert/publish | owner |
| Web/Mobile Resources list | list_my | — |
| Web/Mobile point visual | get plan + list binds | upsert binds / set plan |
| Mobile/Web guest booking | get published + binds | create booking (как сейчас) |

Flutter-модель = контракт полей SPEC, не наоборот.

---

## Вне скоупа этой SPEC v1

- `venue_bookables` / inventory  
- `attendance` view helpers  
- Колонка `bookings.space_node_id` (можно follow-up)  
- Storage bucket для превью PNG (опц. later)  

---

## Чеклист перед apply

- [ ] Процесс + ТЗ не противоречат  
- [ ] RLS/RPC не обходятся  
- [ ] EN-ключи status  
- [ ] INDEX на FK/list  
- [ ] Mobile и web на одних именах полей  
- [ ] Запись в MIGRATIONS_INDEX  
