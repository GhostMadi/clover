# ТЗ: посещаемость + слой тегов

**Статус:** ТЗ к реализации (процесс готов к нарезке работ)  
**Платформы:** мобилка (Flutter) **и** сайт (`web/`) — паритет  
**Чеклист цикла:** [_feature-lifecycle-checklist.md](_feature-lifecycle-checklist.md)

**База (как уже работает посещаемость):** [attendance.md](attendance.md)  
**Слой тегов (правила):** [tag-powers.md](tag-powers.md)  
**UI кнопок на профиле:** [profile-service-shortcuts.md](../code/ui/profile-service-shortcuts.md)  
**Бэк (текущий):** [SPEC_ATTENDANCE_SYSTEM.md](../supabase/SPEC_ATTENDANCE_SYSTEM.md)  
**Ориентир по паттерну:** [booking-tz.md](booking-tz.md)

Этот файл — **единое ТЗ** на доработку посещаемости уже **со слоем тегов**. Не дублирует весь [attendance.md](attendance.md): ссылается на него и фиксирует дельту + контракт приёмки.

---

## Главное ограничение (не ломать ядро)

**Логика посещаемости уже правильная** — её **не переписываем**.

Остаётся как есть в [attendance.md](attendance.md) / SPEC:

- компания (workplace), геозона, типы отметок;
- invite → Accept в чате → membership;
- punch / ack / absences / duty / OT / payroll preview / analytics;
- 0 лишних запросов для неучастника.

**Здесь другое:**

1. **Удобство и гейты** — входы через теги (`attendance` / `attendanceWork`), две линии на профиле; ярлык из prefs / localStorage **убрать**.  
2. **Строгость как у записи** — создать компанию без тега `attendance` нельзя (фронт **и** бэк). Punch без `attendanceWork` нельзя.  
3. **Статус «неактивен»** — membership может быть, но без `attendanceWork` работник для админа **не полноценный** (не punch, в списке — неактивен).

```
Ядро attendance        = не трогать (логика верная)
Удобство входа         = теги + линии кнопок на профиле
Гейты create / punch   = строго теги (front + RPC)
Без attendanceWork     = membership ок, punch нет, админ видит «неактивен»
```

Слово «работник» в доках = **короткая метка линии UI** (верх), не должность и не подчинение: два равных аккаунта (admin + worker).

---

## 1. Смысл и границы

**Зачем:** включать и открывать уже работающую посещаемость через теги; запретить create/punch без нужной силы; админу видеть, кто ещё не включил worker-тег.

**Не является:**
- переписыванием геозоны / punch / payroll / duty;
- иерархией «админ над работником» как кастой;
- CRM / лицом / live-трекингом;
- записью ([booking.md](booking.md) / [booking-tz.md](booking-tz.md)).

**Граница v1 этого ТЗ:** теги + гейты + inactive-флаг + паритет платформ по **входам**. Happy path из [attendance.md](attendance.md) **сохраняем**.

**Punch / GPS / outbox отметок — только мобилка.** На сайте worker смотрит детали (read); «Отметиться» нет ([website-attendance-gaps.md](website-attendance-gaps.md)).

---

## 2. Участники (сценарии, не касты)

Все равны: один аккаунт может совмещать сценарии.

| Сценарий | Условие | Что делает |
|----------|---------|------------|
| **Админ компании** | тег **`attendance`** | Создаёт компании, геозона, invite, табель, аналитика; нижняя линия «Управление» |
| **Работник с punch** | membership **и** тег **`attendanceWork`** | Punch, ack, свои детали; верхняя линия «Посещаемость» |
| **Membership без worker-тега** | invite accepted, **нет** `attendanceWork` | В команде есть; punch **запрещён**; у админа статус **«Неактивен»** |
| **Не участвует** | нет тегов и нет membership | 0 кнопок, 0 attendance-запросов |

Кнопка worker-линии появляется от тега `attendanceWork` (как `bookingCalendar`). Пустой хаб без membership — норма. Punch — только при membership + тег.

---

## 3. Сущности (для ТЗ)

| Сущность | Смысл |
|----------|--------|
| Account-тег `attendance` | Сила ведения компаний / admin-хаба |
| Account-тег `attendanceWork` | Сила полноценного работника (punch + worker UI) |
| Workplace / membership / punch | Как в [attendance.md](attendance.md) |
| Флаг `has_attendance_work_tag` | В bootstrap membership → UI «Неактивен» для админа |

---

## 4. Слой тегов — требования

### 4.1 Ключи

| Ключ (EN) | Группа | Линия на профиле | Сила |
|-----------|--------|------------------|------|
| `attendance` | account → **admin** | **нижняя** | Admin-хаб, create company, настройки |
| `attendanceWork` | account → **worker** | **верхняя** | Punch + worker-хаб |

Подписи — только фронт ([localization-dictionaries.md](localization-dictionaries.md)).  
Ключи — в каталог бэка + enum/catalog мобилки + web catalog.

### 4.2 Правила силы (обязательные)

| # | Правило |
|---|---------|
| T1 | Нет тега → нет кнопки этой силы и клиент **не** стартует связанные сценарии «на всякий случай» |
| T2 | Один тег = один набор сил; `attendance` ≠ `attendanceWork` |
| T3 | Тег выбирает сам пользователь в **Редактировать профиль** |
| T4 | Источник правды ярлыка админа — **тег с бэка**, не prefs / localStorage |
| T5 | RLS/RPC обязательны; фронт-гейт не замена политике |
| T6 | Мобилка и сайт — одинаковые условия показа и смыслы |
| T7 | **Create company** без `attendance` → **запрещено** (UI + `attendance_create_workplace`) |
| T8 | **Punch** без `attendanceWork` → **запрещено** (UI + `submit_attendance_punch`), даже при active membership |
| T9 | Accepted membership без `attendanceWork` → админ видит **«Неактивен»** (не punch-ready) |

### 4.3 Две линии кнопок на своём профиле

Полный паттерн: [profile-service-shortcuts.md](../code/ui/profile-service-shortcuts.md).

| Требование | Деталь |
|------------|--------|
| Верх | `attendanceWork` → «Посещаемость» (worker) |
| Низ | `attendance` → «Управление» (admin) |
| Плотность | ≤2 → иконка + текст; ≥3 → только иконка |
| Пусто | линия не рисуется |
| Убрать | тоггл «кнопка в профиле» / shortcut prefs |

---

## 5. Жизненный цикл (с тегами)

### 5.1 Админ (`attendance`)

| Фаза | Как |
|------|-----|
| Создать / включить | Edit profile → тег `attendance` → сохранить |
| Активировать | Нижняя линия + Настройки → Посещаемость |
| Действовать | Создать компанию, invite, правила, табель |
| Выключить | Снять тег → кнопки/хаб входа пропадают; create/update admin write на бэке — forbidden |

### 5.2 Работник (`attendanceWork`)

| Фаза | Как |
|------|-----|
| Подключить данные | Admin invite → Accept в чате → membership |
| Включить силу | Edit profile → тег `attendanceWork` |
| Активировать | Верхняя линия; punch доступен |
| Без тега при membership | В списке у админа «Неактивен»; punch RPC → error |
| Выключить | Снять тег → кнопки нет; membership остаётся |

### 5.3 Админ смотрит сотрудников

Вкладка «Активные» (accepted):

- есть `attendanceWork` → обычный активный;
- нет `attendanceWork` → **Неактивен** (подзаголовок / бейдж), детали и архив доступны.

---

## 6. Карта экранов и входов

### 6.1 Входы

| Вход | Условие | Куда | Платформы |
|------|---------|------|-----------|
| Нижняя линия → Управление | тег `attendance` | Admin hub | mobile + web |
| Верхняя линия → Посещаемость | тег `attendanceWork` | Worker hub (пусто без membership) | mobile + web |
| Настройки → Посещаемость | тег `attendance` | Admin hub / компании | mobile + web |
| Punch | membership active + `attendanceWork` + geofence… | Punch flow | **mobile only** |
| Сайт worker | тег `attendanceWork` (+ membership) | Read-only хаб / детали | web (без punch) |

### 6.2 Меняемые экраны

| Экран | Действие ТЗ |
|-------|-------------|
| Свой профиль — 2 линии | Гейт по тегам attendance* |
| Settings → Сервисы → Посещаемость | Только при `attendance`; убрать тоггл ярлыка |
| Create company | Фронт + RPC: нужен `attendance` |
| Workers list | Бейдж «Неактивен» без `attendanceWork` |
| Edit profile — теги | Можно выбрать оба независимо |

---

## 7. Таблица решений (зафиксировано)

| Тема | Решение |
|------|---------|
| Ключи | `attendance` + `attendanceWork` |
| Иерархия ролей | Нет; только теги и сценарии |
| Ярлык админа | Только тег `attendance`; prefs/localStorage — убрать |
| Punch без worker-тега | **Строго запретить** (как host-write booking без `booking`) |
| Membership без worker-тега | Разрешить; админ видит **неактивен** |
| Create без admin-тега | **Нельзя** (front + back) |
| Паритет с записью | Тот же паттерн: `booking` / `bookingCalendar` |
| Паритет платформ | Mobile = web по смыслу гейтов |
| Правда UI vs бэк | Фронт режет UI; RPC всё равно проверяет тег |

---

## 8. Сеть / sync / сессии

| Тема | Решение |
|------|---------|
| Источник тегов | Профиль с бэка |
| Offline ярлык | Не хранить «shortcut on» в prefs |
| Bootstrap | Membership JSON: `has_attendance_work_tag` |
| 0 трафика | Без тегов и без локального membership — не звать bootstrap «на всякий случай» |

---

## 9. Вне скоупа (явно)

- Переписывание ядра punch / payroll / duty
- Автовыдача `attendanceWork` при Accept invite
- Punch на сайте, если ещё в gap-плане
- Один тег на оба сценария
- Ярлык только в device cache

---

## 10. Нарезка работ (порядок)

### WP0 — Документы и каталог
- [x] attendance-tz, правки tag-powers / attendance.md / features-catalog / README  
- [x] Ключи в localization / catalog-sync (ссылка)

### WP1 — Каталог тегов
- [x] Бэк: `attendance`, `attendanceWork` в `marker_tags`  
- [x] Flutter enum + `serviceKind`  
- [x] Web `MARKER_TAGS` + `tagServiceKind`

### WP2 — RPC гейты
- [x] `profile_has_marker_tag`  
- [x] `attendance_create_workplace` / admin write → тег `attendance`  
- [x] `submit_attendance_punch` → тег `attendanceWork`  
- [x] bootstrap: `has_attendance_work_tag`  
- [x] Booking: host create/ops уже через `booking_host_has_booking_tag` (паритет задокументировать)

### WP3 — Профиль / settings
- [x] Mobile: линии по тегам; убрать shortcut store  
- [x] Settings → Посещаемость только при `attendance`  
- [x] Web: то же + cabinet rail без localStorage shortcut

### WP4 — Inactive для админа
- [x] Workers UI: «Неактивен» без `attendanceWork`  
- [x] Front create company: гейт по тегу

### WP5 — Приёмка
- [ ] Чеклист §11

---

## 11. Приёмка

- [ ] Без `attendance` нет нижней кнопки и пункта Настройки → Посещаемость  
- [ ] Create company без тега → UI не даёт / RPC error  
- [ ] Без `attendanceWork` нет верхней кнопки punch-хаба  
- [ ] Active membership без `attendanceWork` → админ видит «Неактивен»; punch RPC fails  
- [ ] С тегами — happy path attendance.md работает  
- [ ] Нет зависимости от prefs/localStorage ярлыка  
- [ ] Паритет mobile / web по гейтам  
- [ ] Booking: create/host-write без `booking` по-прежнему forbidden на бэке; UI хозяина только с тегом

---

## 12. Связи

| Документ | Роль |
|----------|------|
| [attendance.md](attendance.md) | Базовый процесс |
| [tag-powers.md](tag-powers.md) | Глобальные правила тегов |
| [booking-tz.md](booking-tz.md) | Эталон того же паттерна для записи |
| [profile-service-shortcuts.md](../code/ui/profile-service-shortcuts.md) | Две линии |
| [SPEC_ATTENDANCE_SYSTEM.md](../supabase/SPEC_ATTENDANCE_SYSTEM.md) | Контракт бэка |
| [features-catalog.md](features-catalog.md) | Статус фичи |
