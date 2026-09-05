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
| Adaptive iOS/Android | 🟡 старт: `AppShimmer`, `AppRefresh`, `AppSwitch`/`AppSwitchRow` → `AdaptiveStatelessWidget`; остальное — при правках |
| Concrete repo only | 🟡 много `abstract` + Impl (~35) |
| Docs-first | 🟡 сильные зоны (auth/profile/posts); booking/chat/bonus без бизнес-дока |
| Тема через `context.colors` | ✅ shared + feature presentation |

---

## 1. `lib/core/shared/` — переиспользуемые виджеты

Цель правил: shared = единственное место смены UI; сразу тема + нативность.

### Core controls

| Виджет | Тема (`of` / colors) | Adaptive | Icons / styles | Вердикт |
|--------|----------------------|----------|----------------|---------|
| `platform/` (`AppPlatform`, `AdaptiveStatelessWidget`) | ✅ база | ✅ | — | ✅ |
| `app_button.dart` | ✅ `context.colors` | ❌ | styles ✅ | 🟡 |
| `app_outlined_button.dart` | ✅ | ❌ | ✅ | 🟡 |
| `app_text_button.dart` | ✅ | ❌ | ✅ | 🟡 |
| `app_field.dart` | ✅ | ❌ | `IconData?`, не AppIcons | 🟡 |
| `app_switch.dart` | ✅ | ✅ `Switch.adaptive` + `AdaptiveStatelessWidget` | ✅ | ✅ |
| `app_dialog.dart` | ✅ (+ barrier `Colors.*`) | ❌ | ✅ | 🟡 |
| `app_bottom_sheet.dart` | ✅ | ❌ (обёртка modal — ок) | ✅ AppIcons | 🟡 |
| `app_snack_bar.dart` | ✅ | ❌ | ✅ AppIcons | 🟡 |
| `app_refresh.dart` | ✅ | ✅ `AdaptiveStatelessWidget` | — | 🟡 |
| `app_shimmer.dart` | ✅ `context.colors` | ✅ `AdaptiveStatelessWidget` | — | ✅ |
| `jelly.dart`, `gestures/`, `switchable_stack` | n/a | n/a | n/a | ✅ infra |

### Nav / tiles

| Виджет | Тема | Adaptive | Icons/styles | Вердикт |
|--------|------|----------|--------------|---------|
| `app_nav_bar/` | ✅ `context.colors` | ❌ | IconData снаружи | 🟡 |
| `app_tab.dart` | ✅ | ❌ | ✅ | 🟡 |
| `app_tile.dart` | ✅ | ❌ | ✅ AppIcons | 🟡 |
| `app_mini_menu.dart` | ✅ | ✅ `AdaptiveStatelessWidget` | ✅ AppIcons | 🟡 |

### Selectors / pickers

| Виджет | Тема | Adaptive | Icons/styles | Вердикт |
|--------|------|----------|--------------|---------|
| `app_single_selctor.dart` | ✅ | ❌ | ✅ AppIcons, RU strings | 🟡 |
| `app_multi_selector.dart` | ✅ | ❌ | ✅ AppIcons, RU strings | 🟡 |
| `app_picker_common.dart` | ✅ | ❌ | ✅ AppIcons | 🟡 |
| `app_date_picker.dart` | ✅ | ❌ | RU | 🟡 |
| `app_time_picker.dart` | ✅ | ❌ | RU | 🟡 |
| `app_smile_picker.dart` | ✅ | ❌ | ✅ | 🟡 |

### Map / functional / media

| Виджет | Тема | Adaptive | Icons/styles | Вердикт |
|--------|------|----------|--------------|---------|
| `app_functional_button/` | ✅ | ❌ | ✅ AppIcons | 🟡 |
| `app_map/` | ✅ (+ `AppColorBinding` для bitmap) | ❌ | raw TextStyle на emoji | 🟡 |
| `image_select/` | ✅ | ❌ | ✅ AppIcons | 🟡 |

### Shared — миграция темы

1. ~~Весь `lib/core/shared/`~~ → ✅ `context.colors` + `AppIcons`
2. Остаётся: `AdaptiveStatelessWidget` в контролах (не блокер)
3. Map marker default border hex → токен палитры (косметика)

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
| `cluster_create` | yes | ok | мало | partial | ✅ |
| `_booking_/booking_settings` | yes | ok | мало | нет | ✅ |
| `_booking_/booking_analytics` | yes | ok | мало | нет | ✅ |
| `_booking_/my_bookings` | yes | leak | мало | нет | ✅ |
| `_bonus_/bonus_history` | yes | ok | мало | нет | ✅ |
| `auth` | partial (core/auth) | ok | Icons | authentication | 🟡 |
| `onboarding` | partial | ok | dirty | onboarding | 🟡 |
| `dashboard_page` | partial | ok | ok | navigation-bars | 🟡 |
| `_profile_/profile_page` | yes | leak | dirty | profile | 🟡 |
| `_profile_/edit_profile` | yes | ok | dirty | profile | 🟡 |
| `_post_/post` | yes | leak | dirty | publications | 🟡 |
| `_feed_/events_page` | yes | leak | dirty | publications | 🟡 |
| `_feed_/map_page` | yes | ok | dirty | publications | 🟡 |
| `_feed_/notification_page` | yes | ok | dirty | нет | 🟡 |
| `_profile_/followers_and_followings` | yes | leak | ok | partial | 🟡 |
| `_cluster_/cluster` | partial | ok | dirty | partial | 🟡 |
| `_post_/post_comment` | partial | leak | dirty | нет | 🟡 |
| `_post_/post_share` | partial | leak | dirty | нет | 🟡 |
| `_chat_/message_page` | partial | leak | dirty | нет | 🟡 |
| `_chat_/chat_page` | partial | leak | dirty | нет | 🟡 |
| `_settings_/settings` (+ about/account/resources) | thin pages | ok | разный | нет / partial | 🟡 |
| `_settings_/settings_filter` | yes | leak | dirty | нет | 🟡 |
| `_settings_/settings_saved_post` | yes | ok | ok | нет | 🟡 |
| `_archive_/post_archive` | yes | leak | ok | нет | 🟡 |
| `_archive_/event_archive` | yes | leak | ok | нет | 🟡 |
| `_archive_/settings_archive` | no | ok | dirty | нет | 🟡 |
| `_booking_/booking_create` | yes | leak | dirty | нет | 🟡 |
| `_booking_/booking_list` | yes | leak | dirty | нет | 🟡 |
| `_booking_/booking_client` | yes | ok | dirty | нет | 🟡 |
| `_bonus_/my_bonuses` | yes | ok | dirty | нет | 🟡 |
| `_catalog_/location` | yes | ok | dirty | нет | 🟡 |
| `_bonus_/bonus_settings` | yes | ok | dirty | нет | 🟡 |
| `_cluster_/cluster_archive` | yes | ok | ok | нет | 🟡 |

### Catalog / data helpers (не экраны)

| Feature | Роль | Вердикт |
|---------|------|---------|
| `_catalog_/city`, `_catalog_/countries`, `_catalog_/marker_tags` | enum + catalog + select | ✅ helper |
| `_chat_/chat`, `_catalog_/social_graph` | data-only | ✅ |
| `_booking_/shared`, `_bonus_/shared` | группа | 🟡 / ✅ |

---

## 3. Сводка одним взглядом

### По правилам UI / shared

| | |
|--|--|
| ✅ | База adaptive (`platform/`); sheet-API единый; типографика в shared часто через `AppTextStyle` |
| 🟡 | Icons: feature presentation → `AppIcons` (0 сырых `Icons.*` кроме onboarding); shared ✅ |
| 🔴 | `image_select/` — RU strings, `Colors.transparent` (остаточный долг) |

### По фичам (логика правил)

| | |
|--|--|
| ✅ ближе всех | `post_create`, `cluster_create`, booking_settings/analytics/my_bookings, bonus_history + catalog helpers |
| 🟡 основная масса | profile/post/map/events/chat/settings/booking_create… — каркас есть, долг Icons + leak uid + мало docs |
| 🔴 чинить первыми | `location`, `bonus_settings`, `cluster_archive` (page→repo); пустые stubs booking |

### Docs (пересечение с features-catalog)

Уже описаны продуктово: auth, onboarding, nav, profile, publications, localization, catalog-sync.  
Без отдельного бизнес-дока, но код есть: booking, bonus, chat, comments, share, archives, notifications, filters, location, clusters.

---

## 4. Как обновлять этот файл

После миграции shared или приведения фичи к каркасу — поменять вердикт в таблице.  
Новая фича: строка сюда **и** в [features-catalog.md](../business/features-catalog.md) (там продукт, здесь правила).
