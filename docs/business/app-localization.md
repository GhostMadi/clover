# Локализация приложения (ru / en / kk)

**Статус:** актуально  
**Связано с:** [localization-dictionaries.md](localization-dictionaries.md), [settings.md](settings.md), [catalog-sync.md](catalog-sync.md)

---

## Зачем

Мобильное приложение Clover переключается между **русским**, **английским** и **казахским** без смены контракта бэка. Бэк по-прежнему отдаёт только **английские ключи** справочников.

Сайт (`web/`) в этом контуре не входит — отдельный проход.

---

## Стек

| Часть | Где |
|-------|-----|
| gen-l10n + ARB | `l10n.yaml`, `lib/l10n/app_ru.arb` (шаблон), `app_en.arb`, `app_kk.arb` |
| Доступ в UI | `context.l10n` (`lib/core/extension/context.dart`) |
| Локаль | `AppLocaleCubit` + `AppLocaleStore` (prefs) → `MaterialApp.locale` |
| Переключатель | Настройки → Аккаунт → Язык |
| Даты / месяцы / дни недели | `intl` через [`AppDateFormat`](../../lib/core/locale/app_date_format.dart) / `context.dateFormat` — **не** ключи ARB |

Системные permission-строки (Info.plist / Android `values-*`) — отдельно от ARB.

---

## Правила ключей

### 1. Общие — `common_*`

Короткие фразы **без** контекста экрана: `common_save`, `common_cancel`, `common_back`, `common_error`…

- Одно значение = одно понятие.
- Длинные объяснения и экранные заголовки — **не** common.
- «Удалить» кнопкой ≠ «Удалить аккаунт» заголовок.

### 2. Экранные — `{area}_{code}`

Текст с риском разного смысла: `settings_account_deactivate_title`, `auth_login_terms_required`, `booking_inbox_…`.

- Префикс = зона фичи / route-группа.
- Не переиспользовать между фичами, даже если RU совпадает.

### 3. Справочники — `catalog_*`

Ключи вида `catalog_city_almaty`, `catalog_tag_salon`. Enum на фронте: getter `label(AppLocalizations)` / extension, не `labelRu` как единственный источник.

### 4. Ошибки / push — `error_*`, `push_*`

Auth/network snackbars и клиентские push-заголовки — через l10n, не сырой RU в коде.

### Прочее

- Ключ: **snake_case + латиница**; значение — перевод.
- Плейсхолдеры ICU (`{count}`, `{name}`), не склейка строк.
- **Даты / месяцы / дни недели** — только `context.dateFormat` / `AppDateFormat` (`intl`), не ARB и не массивы `'Январь'…`.
- **Не** переводить: ники, UGC, EN-ключи с бэка, logical status codes.
- Новая строка: сначала `app_ru.arb`, потом en/kk, потом код.
- После миграции экрана — без сырого RU в виджете (ошибки/snackbar тоже).

```
Widget copy → универсально? → common_* : area_*
Catalog enum → catalog_* / l10n getter
Backend EN key → catalog enum (не перевод с бэка)
```

---

## Как добавить строку

1. Ключ в `lib/l10n/app_ru.arb`
2. Те же ключи в `app_en.arb` и `app_kk.arb`
3. `flutter gen-l10n` (или следующий `flutter pub get` / build)
4. В UI: `context.l10n.someKey` (camelCase от snake_case)

---

## Волны миграции

Порядок: фундамент → auth/settings → feed/profile/ugc → chat → booking → attendance → resources/bonus/venue/archive → catalogs → errors/push.

Критерий волны: нет хардкода RU на затронутых экранах; en + kk заполнены; смена языка обновляет UI без рестарта (rebuild `MaterialApp`).
