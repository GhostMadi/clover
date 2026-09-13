# Админка сайта (скрытый вход)

**Статус:** актуально · заполнение v1  
**Связано с:** [website.md](website.md), [website-deploy.md](website-deploy.md), [support.md](support.md)

**Не про:** кабинет пользователя `/app`, теги `admin` booking/attendance.

---

## Зачем

Служебная панель владельца Clover: ops + платформенная аналитика. Не в меню, не в кабинете.

---

## Кто

| Роль | Что делает |
|------|------------|
| Владелец / оператор (`profiles.is_site_admin`) | 15 тапов → `/admin` → email/пароль → хаб |
| Обычный посетитель | Без пароля / флага не войдёт |

---

## Как попасть

1. Футер публичных страниц — **15 тапов** по «© … Clover».
2. `/admin` — email + пароль аккаунта с `is_site_admin`.
3. `/admin/home` — хаб модулей (cookie `clover_admin_session` + проверка флага).
4. Выход — «Выйти».

Назначить админа (SQL):

```sql
update public.profiles set is_site_admin = true where email = 'твой@email.com';
```

Env: `ADMIN_SESSION_SECRET`, `SUPABASE_SERVICE_ROLE_KEY` (только серверные `/api/admin/*`).

---

## План заполнения (roadmap)

| Фаза | Модуль | Статус | URL |
|------|--------|--------|-----|
| **A** | Хаб + навигация | 🟢 | `/admin/home` |
| **A** | Support inbox | 🟢 | `/admin/support` |
| **A** | Платформенная аналитика (карточки) | 🟢 | `/admin/analytics` |
| **A** | Honest Quiz (временное) | 🟢 | `/admin/honest` |
| **B** | Модерация постов / жалобы | 🔴 позже | `/admin/moderation` |
| **B** | Пользователи (поиск, флаг admin) | 🔴 позже | `/admin/users` |
| **C** | Тренды 30д, алерты квот | 🔴 позже | analytics v2 |

Не класть сюда: booking/attendance host-ops — это `/app/settings/…`.

---

## Карта экранов (фаза A)

| URL | Что |
|-----|-----|
| `/admin` | Логин |
| `/admin/home` | Хаб: Support · Аналитика · Honest Quiz · Кабинет |
| `/admin/support` | Список заявок, смена статуса |
| `/admin/analytics` | DAU / юзеры / сервисы / контент / ops |
| `/admin/honest` | Прохождения честного теста |

---

## Аналитика (фаза A) — метрики

Период: `1` / `7` / `30` дней (для «активности»).

| Ключ (EN) | Смысл |
|-----------|--------|
| `profiles_total` | Всего профилей |
| `dau` | Уникальные `user_id` в `account_login_events` за 1д |
| `active_logins` | Уникальные логины за период |
| `new_profiles` | Новые профили за период |
| `tag_booking` / `tag_attendance` / `tag_resources` | Профили с силовым тегом |
| `booking_points` | Точек записи |
| `attendance_workplaces` | Компаний посещаемости |
| `bookings_period` | Записей за период |
| `punches_period` | Отметок за период |
| `posts_period` | Постов за период |
| `support_new` | Заявки support в статусе `new` |
| `honest_quiz_finished` | Завершённые прогоны квиза |

Контракт: RPC `admin_platform_stats` → [SPEC](../supabase/SPEC_ADMIN_PLATFORM.md).  
Support admin: [SPEC_SUPPORT_REQUESTS](../supabase/SPEC_SUPPORT_REQUESTS.md).

---

## Безопасность

- Cookie HMAC + email должен иметь `is_site_admin`.
- API `/api/admin/*` после гейта ходит в БД через **service_role** (RLS клиентских ролей не обходим «с браузера»).
- Не путать с тегом `admin` профиля.

---

## Связанные

- Деплой: [website-deploy.md](website-deploy.md)
- Support продукт: [support.md](support.md)
