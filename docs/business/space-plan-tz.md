# ТЗ: схемы пространства (Ресурсы) + Запись по схеме

**Статус:** ТЗ к реализации (процесс COP готов)  
**Платформы:** мобилка (Flutter) **и** сайт (`web/`) — паритет по витрине/bind; рисовалка **только web**  
**Чеклист цикла:** [_feature-lifecycle-checklist.md](_feature-lifecycle-checklist.md)

**База процесса:**

| Документ | Роль |
|----------|------|
| [space-plan-resources.md](space-plan-resources.md) | Ресурс схемы: жизнь, роли, bind к сущностям |
| [space-plan-emoji-pricing.md](space-plan-emoji-pricing.md) | Запись + emoji → услуга/мастер + guest path |
| [booking.md](booking.md) | Ядро записи (не ломать) |
| [booking-points.md](booking-points.md) | Точки хозяина |
| [venue-seating.md](venue-seating.md) | Бронь — другой сервис, та же схема-ресурс |
| [resources-guide.md](resources-guide.md) · [tag-powers.md](tag-powers.md) | Хаб Ресурсов / тег `resources` |
| [venue-plan-json.md](venue-plan-json.md) | Контракт JSON геометрии |

**Бэк (целевой):** [SPEC_SPACE_PLANS.md](../supabase/SPEC_SPACE_PLANS.md)  
**Mock уже есть:** web Resources + booking visual · mobile guest/host bind

Этот файл — **единое ТЗ** на нарезку работ. Не дублирует процессы выше: фиксирует дельту, work packages, приёмку.

---

## Главное ограничение

```
Ядро booking (слоты, confirmed, inbox)  = не переписывать
Ядро resources (locations / filters)    = не ломать
Схема                                 = новый справочник в Ресурсах
Слой Записи на схеме                   = bind на точке + guest path
Слой Брони на схеме                    = отдельно (venue), не в этом WP-срезе v1 бэка Записи
```

**Новых тегов нет.** Сила рисовалки/списка схем = уже существующий `resources`.  
Сила точки записи = `booking`. Схема не отдельный «сервис-тег».

---

## 1. Смысл и границы

**Зачем:** хозяин один раз рисует зал в Ресурсах → вешает на точку Записи → гости выбирают место на плане или идут классическим путём услуги.

**Не является:**

- переписыванием create_booking / статусов визита;
- CRM / кассой / inventory «кресло занято» как у Брони;
- новым тегом `space_plans`;
- рисовалкой на мобилке;
- обязательным полем при create точки.

**Граница v1 этого ТЗ:**

1. Ресурс `space_plans` (CRUD + publish) на сайте; список/превью на mobile+web.  
2. `space_plan_id` на `booking_points` + таблица emoji-binds.  
3. Host bind UI (web основной, mobile mock→prod).  
4. Guest: схема → услуга/мастер → слот → запись (тот же RPC create).  
5. Паритет ключей EN / один контракт mobile↔web.

**Сознательно позже (не блокирует приёмку v1):** venue bookable inventory на той же схеме; attendance view-only; `space_node_id` колонка на `bookings` (можно note в client_notes).

---

## 2. Участники

| Сценарий | Условие | Делает |
|----------|---------|--------|
| Автор схем | тег **`resources`** | Создаёт / правит / publish / архив схем (сайт) |
| Хозяин точки | тег **`booking`** + точка | Вешает схему; bind emoji → услуга (± staff) |
| Гость | авторизован, чужой профиль с `booking` | Путь A (схема) или B (услуга) → запись |
| Без `resources` | — | Хаб Ресурсов / схемы **не** видны (0 лишней работы) |
| Без схемы на точке | — | Карточки схемы у гостя нет; только путь B |

---

## 3. Сущности (контракт смысла)

| Сущность | EN | Смысл |
|----------|-----|--------|
| Схема | `space_plan` | Геометрия: floors + nodes; status draft/published/archived |
| Узел | `node` | Фигура / emoji / text в JSON; emoji + `role: bookable` = место |
| Ссылка | `space_plan_id` | FK на сущности сервиса (v1: `booking_points`) |
| Bind Записи | `booking_space_emoji_bind` | `(point_id, node_id)` → `service_id` + опц. `staff_id` |
| Услуга / staff / booking | как booking.md | Цена только с услуги; слоты мастера |

**Мозаика:** геометрия ≠ bind ≠ запись.

---

## 4. Жизненные циклы (приёмка процесса)

### Ресурс

Создать → рисовать (web) → publish → привязать к точке → гость читает → отвязать / архив → удалить только без ссылок.

### Запись + схема

Схема на точке → ≥1 bind на bookable emoji → гость тап → дата/слот → «Записаться» → confirmed → inbox.

Без bind / без схемы — классика booking.md без регрессии.

---

## 5. Карта экранов (целевая)

| Экран | Платформа | WP |
|-------|-----------|-----|
| Ресурсы → Схемы (список) | mobile + web | WP1 |
| Редактор схемы | **web only** `/app/settings/resources/space-plans/[id]/edit` | WP1 |
| Legacy venue editor | web `/settings/venue/.../plan` | WP1: редирект / пометка «переехало в Ресурсы» |
| Точка → Схема и ценники | mobile + web | WP2 |
| Create/edit точки → поле схемы | mobile + web | WP2 |
| Guest BookingClient + fullscreen схема | mobile (+ web later) | WP3 |

---

## 6. Стыки → решения (закреплено)

| Тема | Решение |
|------|---------|
| Теги | Только `resources` + `booking`; нового тега схем нет |
| Рисовалка | Продуктовый дом = **Ресурсы**; venue-path — legacy mock до снятия |
| JSON ресурса | Только геометрия (+ role bookable/decor на emoji). Каталог услуг / bookable **не** в ресурсе |
| Ценник Записи | Только emoji bookable; цена из `booking_services` |
| Занятость Записи | Слоты staff, не inventory кресла |
| Бронь (venue) | Свой слой bookable×occasion; тот же `space_plan_id` позже |
| Одна CTA «Записаться» | В теле формы гостя; не дубль у кнопки назад |
| Удаление схемы | Нельзя при живых `space_plan_id` ссылках |

---

## 7. Сеть / sync

| Что | Правило |
|-----|---------|
| Publish | Сервер = правда; клиенты тянут published version |
| Bind | Пишет только host точки; RLS |
| Create booking | Online; опц. node_id в notes / later column |
| Offline | Просмотр кэша схемы ок; confirm нет |
| Logout | Wipe локальных draft/mock ключей user |

---

## 8. Уведомления

Без новых каналов. Create/cancel записи — как [booking.md](booking.md). Publish схемы — без push.

---

## 9. Вне скоупа v1

- Рисовалка mobile  
- Venue inventory / soft-hold на этой схеме  
- Attendance punch по клеткам  
- Мультивыбор мест одной записью  
- Оплата за место  
- Публичный просмотр без аккаунта  
- Новый marker_tag для схем  

---

## 10. Work packages (нарезка)

### WP0 — Документы (этот проход)

- [x] Процесс resources + emoji-pricing COP  
- [x] Выровнять нестыковки (гайд, tag-powers, venue вход, booking шаги)  
- [x] ТЗ + черновик SPEC  
- [ ] Строка каталога → статус по факту бэка  

### WP1 — Ресурс схем (web + list mobile)

- [ ] Таблица / storage JSON `space_plans` по SPEC  
- [ ] Web: список + editor под **Ресурсы** (мок → API)  
- [ ] Mobile: список published своих схем (read + deep link «править на сайте»)  
- [ ] Legacy `/settings/venue/.../plan` → редирект или баннер «дом в Ресурсах»  
- [ ] Хаб Ресурсов: тайл `space_plans` (mobile + web)  
- [ ] `tag-powers` / гайд: сила `resources` включает схемы  

### WP2 — Точка Записи: схема + bind

- [ ] Колонка `booking_points.space_plan_id`  
- [ ] Таблица `booking_space_emoji_binds`  
- [ ] RPC/RLS: host CRUD binds; guest read binds published точки  
- [ ] Web visual bind → API  
- [ ] Mobile host bind → API  
- [ ] Create/edit точки: селектор схемы (опц.)  

### WP3 — Guest path

- [ ] BookingClient: карточка схемы если есть plan+binds  
- [ ] Fullscreen viewer: тап bookable → service/staff  
- [ ] Подстановка в cubit + слоты как сейчас  
- [ ] Confirm: тот же create; опц. сохранить node в notes  
- [ ] Снять mock-only флаги когда API готов  
- [ ] Web guest parity (если ещё нет)  

### WP4 — Дожим

- [ ] Пустые стейты: нет схемы / нет bind / decor only  
- [ ] Запрет удалить схему со ссылками (UI + RPC)  
- [ ] Каталог features → обновить статус  
- [ ] ANALYZE / smoke checklist ниже  

---

## 11. Контракт бэка (ссылка)

Детали таблиц/RLS/RPC — только в [SPEC_SPACE_PLANS.md](../supabase/SPEC_SPACE_PLANS.md).

Минимум v1:

| Объект | Назначение |
|--------|------------|
| `space_plans` | id, owner_id, title, status, plan_json, version, timestamps |
| `booking_points.space_plan_id` | FK nullable |
| `booking_space_emoji_binds` | point_id, node_id, service_id, staff_id? UK(point, node) |
| RLS | owner пишет space_plans; host точки пишет binds; guest читает published+binds витрины |
| RPC | list/get published; upsert binds; set point space_plan; guard delete |

EN-ключи статусов: `draft` \| `published` \| `archived`. Без `name_ru` в таблицах.

---

## 12. Критерии приёмки

### Ресурсы
- [ ] С тегом `resources` виден тайл Схемы; без тега — 0 экранов схем  
- [ ] Создать → publish на сайте; draft не виден гостю  
- [ ] Mobile список видит published; edit → сайт  
- [ ] Нельзя удалить схему, пока на неё ссылается точка  

### Хозяин Записи
- [ ] На точку можно повесить / снять схему  
- [ ] Bind только на emoji bookable; decor недоступен  
- [ ] Цена на витрине = цена услуги  
- [ ] Bulk «одинаковые emoji» копирует bind на каждый node  

### Гость
- [ ] Без схемы — шаги как в booking.md (регрессии нет)  
- [ ] Со схемой: место → услуга/мастер → дата → слот → одна «Записаться»  
- [ ] Запись confirmed; видна хозяину в inbox  
- [ ] Нельзя записаться к себе  

### Паритет / гармония
- [ ] Те же EN-ключи и поля mobile ↔ web  
- [ ] RLS не обходится «скрытой кнопкой»  

---

## 13. Схема одной картинкой

```
tag resources → Ресурсы → Схемы (web draw / publish)
                         ↓ space_plan_id
tag booking  → Точка → binds (node → service ± staff)
                         ↓
Гость: Схема | Услуга → Мастер → Дата → Слот → Записаться
                         ↓
              тот же booking inbox

Бронь / Attendance позже: тот же space_plan + свой слой
```

---

## 14. Связанные файлы при работе

| Документ | Роль |
|----------|------|
| [space-plan-resources.md](space-plan-resources.md) | Процесс ресурса |
| [space-plan-emoji-pricing.md](space-plan-emoji-pricing.md) | Процесс Запись+схема |
| [SPEC_SPACE_PLANS.md](../supabase/SPEC_SPACE_PLANS.md) | Бэк-контракт |
| [SPEC_BOOKING_SYSTEM.md](../supabase/SPEC_BOOKING_SYSTEM.md) | Ядро записи |
| [features-catalog.md](features-catalog.md) | Статус |
| [entity-location-bind-plan.md](entity-location-bind-plan.md) | Паттерн FK как location |
