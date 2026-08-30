# Аудит: фичи и shared vs правила Clover

**Дата:** 2026-08-29  
**Зачем:** отдельно от [features-catalog.md](../business/features-catalog.md) — там продукт (🟢🟡🔴 бизнес/техника). Здесь — **соблюдение правил** (каркас, docs-first, ресурсы, sheet, adaptive).

**Правила:** `docs/code/rules/` (clover-architecture, clover-feature-discipline, …), [`adaptive-widgets.md`](adaptive-widgets.md).

---

## Легенда вердикта

| | Смысл |
|--|--------|
| ✅ | Близко к правилам (каркас ок, sheet ок, без грубых нарушений) |
| 🟡 | Частично: работает, но есть долг (Icons/Colors, abstract repo, нет docs, нет adaptive, uid через Supabase) |
| 🔴 | Далеко: page→repo, нет cubit, сырой hex, мёртвые stubs |

**Общее по проекту (не на каждую строку):**

| Правило | Сейчас |
|---------|--------|
| Sheets в фичах | ✅ везде `AppBottomSheet` (сырых modal в feature нет) |
| Adaptive iOS/Android | ❌ почти нигде (база `AdaptiveStatelessWidget` есть, миграции нет) |
| Concrete repo only | 🟡 много `abstract` + Impl (~35) |
| Docs-first | 🟡 сильные зоны (auth/profile/posts); booking/chat/bonus без бизнес-дока |
| Тема через `of(context)` | 🟡 shared в основном статичный `AppColors.*` |

---

## 1. `lib/core/shared/` — переиспользуемые виджеты

Цель правил: shared = единственное место смены UI; сразу тема + нативность.

### Core controls

| Виджет | Тема (`of` / colors) | Adaptive | Icons / styles | Вердикт |
|--------|----------------------|----------|----------------|---------|
| `platform/` (`AppPlatform`, `AdaptiveStatelessWidget`) | ✅ база | ✅ | — | ✅ |
| `app_button.dart` | ~ static `AppColors` | ❌ | styles ✅ | 🟡 |
| `app_outlined_button.dart` | ~ | ❌ | ✅ | 🟡 |
| `app_text_button.dart` | ~ | ❌ | ✅ | 🟡 |
| `app_field.dart` | ~ | ❌ | `IconData?`, не AppIcons | 🟡 |
| `app_switch.dart` | ~ | ✅ `Switch.adaptive` | ✅ | 🟡 |
| `app_dialog.dart` | ~ + `Colors.*` | ❌ | ✅ | 🟡 |
| `app_bottom_sheet.dart` | ~ | ❌ (обёртка modal — ок) | `Icons.close` | 🟡 |
| `app_snack_bar.dart` | ~ | ❌ | `Icons.*` | 🟡 |
| `app_refresh.dart` | ~ | ❌ | — | 🟡 |
| `app_shimmer.dart` | ❌ hex | ❌ | — | 🔴 |
| `jelly.dart`, `gestures/`, `switchable_stack` | n/a | n/a | n/a | ✅ infra |

### Nav / tiles

| Виджет | Тема | Adaptive | Icons/styles | Вердикт |
|--------|------|----------|--------------|---------|
| `app_nav_bar/` | ✅ `AppColors.of` | ❌ | IconData снаружи | 🟡 |
| `app_tab.dart` | ✅ | ❌ | ✅ | 🟡 |
| `app_tile.dart` | ✅ / ~ | ❌ | `Icons.chevron_*` | 🟡 |
| `app_mini_menu.dart` | ~ | ❌ | `Icons.more_vert` | 🟡 |

### Selectors / pickers

| Виджет | Тема | Adaptive | Icons/styles | Вердикт |
|--------|------|----------|--------------|---------|
| `app_single_selctor.dart` | ~ | ❌ | `Icons.*`, RU strings | 🟡 |
| `app_multi_selector.dart` | ~ | ❌ | то же | 🟡 |
| `app_picker_common.dart` | ~ | ❌ | `Icons.*` | 🟡 |
| `app_date_picker.dart` | ~ | ❌ | `Icons.*`, RU | 🟡 |
| `app_time_picker.dart` | ~ | ❌ | то же | 🟡 |
| `app_smile_picker.dart` | ~ | ❌ | ✅ | 🟡 |

### Map / functional / media

| Виджет | Тема | Adaptive | Icons/styles | Вердикт |
|--------|------|----------|--------------|---------|
| `app_functional_button/` | ~ | ❌ | `Icons.*` в map buttons | 🟡 |
| `app_map/` | частично of; pin/hex | ❌ | raw TextStyle на emoji | 🟡 |
| `image_select/` | ~ + transparent | ❌ | много `Icons.*`, RU | 🔴 |

### Shared — что мигрировать первым

1. `AppButton` / `AppField` / `AppBottomSheet` / `AppDialog` → `AppColors.of` + `AppIcons` + (по желанию) `AdaptiveStatelessWidget`
2. Selectors / pickers / `AppTile` / snack
3. `AppSwitch` как эталон adaptive + of
4. `image_select` + `AppShimmer` (самый тяжёлый долг)
5. Map marker factories (hex → палитра)

---

## 2. `lib/feature/` — экраны и flows

Колонки:

- **Каркас** — models + repo + cubit + page
- **Слой** — UI не бьёт в repo/Supabase напрямую (`ok` / `leak` uid / `fail` page→repo)
- **UI-долг** — сырые Icons/Colors/hex
- **Docs** — бизнес-док есть?

| Feature | Каркас | Слой | UI-долг | Docs | Вердикт |
|---------|--------|------|---------|------|---------|
| `post_create` | yes | ok | мало | publications | ✅ |
| `marker_create` | yes | ok | мало | publications | ✅ |
| `cluster_create` | yes | ok | мало | partial | ✅ |
| `_booking_/booking_settings` | yes | ok | мало | нет | ✅ |
| `_booking_/booking_analytics` | yes | ok | мало | нет | ✅ |
| `_booking_/my_bookings` | yes | leak | мало | нет | ✅ |
| `_bonus_/bonus_history` | yes | ok | мало | нет | ✅ |
| `auth` | partial (core/auth) | ok | Icons | authentication | 🟡 |
| `onboarding` | partial | ok | dirty | onboarding | 🟡 |
| `dashboard_page` | partial | ok | ok | navigation-bars | 🟡 |
| `profile_page` | yes | leak | dirty | profile | 🟡 |
| `edit_profile` | yes | ok | dirty | profile | 🟡 |
| `post` | yes | leak | dirty | publications | 🟡 |
| `events_page` | yes | leak | dirty | publications | 🟡 |
| `map_page` | yes | ok | dirty | publications | 🟡 |
| `notification_page` | yes | ok | dirty | нет | 🟡 |
| `followers_and_followings` | yes | leak | ok | partial | 🟡 |
| `cluster` | partial | ok | dirty | partial | 🟡 |
| `post_comment` | partial | leak | dirty | нет | 🟡 |
| `post_share` | partial | leak | dirty | нет | 🟡 |
| `message_page` | partial | leak | dirty | нет | 🟡 |
| `chat_page` | partial | leak | dirty | нет | 🟡 |
| `settings` (+ about/account/resources) | thin pages | ok | разный | нет / partial | 🟡 |
| `settings_filter` | yes | leak | dirty | нет | 🟡 |
| `settings_saved_post` | yes | ok | ok | нет | 🟡 |
| `archive/post_archive` | yes | leak | ok | нет | 🟡 |
| `archive/event_archive` | yes | leak | ok | нет | 🟡 |
| `archive/settings_archive` | no | ok | dirty | нет | 🟡 |
| `_booking_/booking_create` | yes | leak | dirty | нет | 🟡 |
| `_booking_/booking_list` | yes | leak | dirty | нет | 🟡 |
| `_booking_/booking_client` | yes | ok | dirty | нет | 🟡 |
| `_bonus_/my_bonuses` | yes | ok | dirty | нет | 🟡 |
| `location` | без cubit | **fail** page→repo | dirty | нет | 🔴 |
| `_bonus_/bonus_settings` | без cubit | **fail** | dirty | нет | 🔴 |
| `archive/cluster_archive` | thin | **fail** | ok | нет | 🔴 |
| `_booking_/data`, `_booking_/presentation` | stubs | — | — | — | 🔴 dead |

### Catalog / data helpers (не экраны)

| Feature | Роль | Вердикт |
|---------|------|---------|
| `city`, `countries`, `marker_tags` | catalog + select | ✅ helper |
| `chat`, `social_graph` | data-only | ✅ |
| `cities` | дубль/abstract рядом с city | 🟡 |
| `_booking_/shared`, `_bonus_/shared` | группа | 🟡 / ✅ |

---

## 3. Сводка одним взглядом

### По правилам UI / shared

| | |
|--|--|
| ✅ | База adaptive (`platform/`); sheet-API единый; типографика в shared часто через `AppTextStyle` |
| 🟡 | Почти все контролы на static `AppColors` + `Icons.*`, без AdaptiveStatelessWidget |
| 🔴 | `app_shimmer`, `image_select` (hex / тяжёлый Material) |

### По фичам (логика правил)

| | |
|--|--|
| ✅ ближе всех | `post_create`, `marker_create`, `cluster_create`, booking_settings/analytics/my_bookings, bonus_history + catalog helpers |
| 🟡 основная масса | profile/post/map/events/chat/settings/booking_create… — каркас есть, долг Icons + leak uid + мало docs |
| 🔴 чинить первыми | `location`, `bonus_settings`, `cluster_archive` (page→repo); пустые stubs booking |

### Docs (пересечение с features-catalog)

Уже описаны продуктово: auth, onboarding, nav, profile, publications, localization, catalog-sync.  
Без отдельного бизнес-дока, но код есть: booking, bonus, chat, comments, share, archives, notifications, filters, location, clusters.

---

## 4. Как обновлять этот файл

После миграции shared или приведения фичи к каркасу — поменять вердикт в таблице.  
Новая фича: строка сюда **и** в [features-catalog.md](../business/features-catalog.md) (там продукт, здесь правила).
