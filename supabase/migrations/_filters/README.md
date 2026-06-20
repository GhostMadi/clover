## Profile feed filters

Миграции **не переносить** из корня `supabase/migrations/`. Эта папка — навигатор по домену **фильтры ленты профиля**.

### Идея

- Владелец профиля настраивает **категории** (Размер, Цвет…) и **значения** в настройках.
- `profiles.has_filters` — денормализованный флаг: есть ли ≥1 категория. Клиент читает его из профиля и **не грузит** категории, пока пользователь не откроет шторку фильтра.
- Триггер на `profile_filter_categories` держит `has_filters` в актуальном состоянии при insert/delete категории.

### Таблицы

| Таблица | Назначение |
|---------|------------|
| `profile_filter_categories` | Группа фильтров (`owner_id`, `name`, `sort_order`) |
| `profile_filter_values` | Значения внутри категории (`label`, `sort_order`) |

Прямой DML с клиента **отключён** (`revoke` + RLS). Только RPC.

### RPC

| Функция | Назначение |
|---------|------------|
| `list_profile_filter_categories(p_profile_id)` | JSON `[{id, name, values: [...]}]` — владелец всегда; гости только если `has_filters` |
| `upsert_profile_filter_category(p_name, p_values, p_category_id?)` | Создать/обновить категорию, заменить все значения |
| `delete_profile_filter_category(p_category_id)` | Удалить категорию (каскад значений) |

### Миграция

- `../20260718120000_profile_filters.sql`
