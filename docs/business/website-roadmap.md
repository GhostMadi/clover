# Сайт Clover — дорожная карта (одно место)

**Статус:** живой ориентир  
**Связано с:** [website.md](website.md) · [website-cabinet.md](website-cabinet.md) · [website-gap-plan.md](website-gap-plan.md) · [website-deploy.md](website-deploy.md) · [features-catalog.md](features-catalog.md)

> **Зачем этот файл:** не искать по чатам «что уже сделали». Здесь — карта сайта: что есть, что недавно сделали, куда смотреть дальше.  
> Код сайта — только `web/`. Продукт как у мобилки — здесь в `docs/business/`. Деплой прода сайта — ветка **`web-production`**. Мобилка — **`mobile-production`** ([mobile-deploy.md](mobile-deploy.md)).

Легенда: ✅ есть · 🟡 частично · ❌ нет · 🔜 дальше

---

## Быстрый вход

| Нужно | Куда |
|-------|------|
| Идея лендинга / legal / auth / брент | [website.md](website.md) |
| Кабинет после входа (вкладки, rail) | [website-cabinet.md](website-cabinet.md) |
| Догон мобилки по шагам 1…8 | [website-gap-plan.md](website-gap-plan.md) |
| Домен / Vercel / ветка прода | [website-deploy.md](website-deploy.md) |
| Бронь мест (процесс, ещё не код) | [venue-seating.md](venue-seating.md) |
| Хвосты посещаемости на сайте | [website-attendance-gaps.md](website-attendance-gaps.md) |
| Прод сайт | https://www.clover.com.kz/ |

---

## Что уже на сайте (срез)

| Зона | Статус | Коротко |
|------|--------|---------|
| Лендинг | ✅ | Белый hero, лого + «Clover», 4 сервиса, эмодзи-маркеры на фоне, тоггл темы |
| Legal | ✅ | Privacy / terms в футере |
| Auth | ✅ | Ник/email, OTP, Google; callback `/auth/callback` |
| Кабинет shell | ✅ | Rail / нижний бар, тема светлая/тёмная |
| Лента / карта / профиль / пост | 🟡 | См. gap-plan шаги 1–5 |
| Чаты / уведомления | 🟡 | Есть каркас + основные сценарии |
| Ресурсы | 🟡 | Хаб, локации (сначала адрес кириллицей), фильтры |
| Запись | 🟡 | Хаб + desktop workspace, inbox, услуги, клиентский flow |
| Посещаемость | ✅ admin + worker RO | Punch только в мобилке |
| Бонусы (полный UX) | ❌ | Поля на услуге есть |
| Бронь мест по схеме | ❌ | Только процесс в [venue-seating.md](venue-seating.md) |

Детали фаз и чеклисты — в [website-gap-plan.md](website-gap-plan.md), не дублируем таблицы здесь.

---

## Недавно сделали (журнал)

Пиши сюда коротко после заметных кусков — чтобы не теряться.

### 2026-09 — лендинг + прод

- Компактный белый лендинг: логотип (`/logo.png`), простой текст **Clover**, одна фраза, Войти / Начать, 4 плитки сервисов (цвета как в мобилке).
- Фон: эмодзи из того же набора, что маркеры/ивенты (`EVENT_FILTER_EMOJIS`).
- В шапке: лого + тоггл светлая/тёмная (`ThemeToggle` → prefs как в настройках).
- Убраны лишние блоки («скоро», длинные пояснения, ссылка «Сервисы» в шапке).
- Задеплоено: push в **`web-production`** → Vercel → clover.com.kz.

### 2026-09 — кабинет / запись / prefs (рядом)

- Запись: desktop **workspace** (широкая зона + sub-nav), хаб = плитки + превью inbox.
- Ярлыки сбоку (booking / attendance / resources): prefs через общий `local-storage` helper — не слетают после refresh.
- Локации: сначала адрес на кириллице, латиница опционально ниже.
- Auth: OAuth `code` на `/` → редирект в `/auth/callback`; cookie + security headers.

---

## Как не заблудиться при работе

1. **Сначала продукт** в `docs/business/` (этот файл + соседние), не «сразу код».
2. **Тот же бэк**, что мобилка (RPC / RLS) — сайт не обходит политики.
3. **Код только** в `web/` — Flutter `lib/` не трогаем «заодно», если задача про сайт (и наоборот).
4. **Прод веб** = ветка `web-production` (не `main`). Локально смотри `localhost:3000`, потом пуш.
5. **Догон фич** — нумерация в [website-gap-plan.md](website-gap-plan.md); прогресс ✅/🟡/❌ обновляй там.

---

## Дальше (очередь, не жёсткий спринт)

| # | Что | Ориентир |
|---|-----|----------|
| 1 | Дожать запись (B0–B7 → ✅) и ресурсы | gap-plan 8a / 8b |
| 2 | Хвосты посещаемости | [website-attendance-gaps.md](website-attendance-gaps.md) |
| 3 | Чаты / уведомления polish | gap-plan 6–7 |
| 4 | Бронь мест по схеме — бэк + веб после процесса | [venue-seating.md](venue-seating.md) |
| 5 | Бонусы — полный клиентский UX | gap-plan 8c |

Вне приоритета: онбординг-слайды веба, Phone OTP на сайте, пиксель-паритет Flutter.

---

## Где лежит код (ориентир)

| Что | Путь |
|-----|------|
| Лендинг | `web/src/app/(marketing)/page.tsx` |
| Шапка / футер / тоггл темы | `web/src/components/site-header.tsx`, `site-footer.tsx`, `theme-toggle.tsx` |
| Эмодзи маркеров | `web/src/features/catalog/lib/event-emojis.ts` |
| Тема / locale prefs | `web/src/features/settings/lib/prefs.ts` |
| Кабинет | `web/src/features/cabinet/` |
| Запись / ресурсы / посещаемость | `web/src/features/booking/`, `resources/`, `attendance/` |
| Лого | `web/public/logo.png` |

Правила агента для веба: `.cursor/rules/clover-web-*.mdc`.
