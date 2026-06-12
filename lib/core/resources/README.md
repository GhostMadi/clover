# UI resources (Clover)

При добавлении или правке экранов и shared-виджетов **по умолчанию** используйте связку из трёх мест — так верстка останется консистентной и адаптивной.

## 1. Цвета — `colors.dart` (`AppColors`)

Все цвета приложения живут в одном абстрактном классе `AppColors`. В виджетах **не** создавайте `Color(0xFF…)` напрямую — только токены из `AppColors`.

### Как устроен файл

Цвета сгруппированы по **смысловым слоям** (сверху вниз в `colors.dart`):

| Слой | Назначение | Примеры |
|------|------------|---------|
| **Brand** | Идентичность продукта | `brand`, `primary` |
| **Surfaces** | Фоны страниц и карточек | `pageBackground`, `surface`, `surfaceMuted`, `surfaceSoft*` |
| **Background accents** | Декоративные плоские подложки | `bgSoftMint`, `bgColor` |
| **Borders & dividers** | Обводки, разделители | `border`, `borderInput`, `borderCardGreen`, `divider` |
| **Text system** | Текст и приглушённые иконки | `textColor`, `subTextColor`, `iconMuted`, `textInverse` |
| **States** | Активность, ошибки, мягкие фоны статусов | `activeColor`, `error`, `successSoft`, `infoSoft` |
| **Shadows** | Базовые цвета теней | `shadowDark`, `shadowPrimary` |
| **Interactive** | Кнопки, поля, нижняя навигация | `btn*`, `field*`, `bottomBar*` |
| **Feature-specific** | Токены одной фичи | `postEditor*` |
| **Misc** | Разовые/редкие цвета | `postShareIcon` |

Часть токенов **ссылается на другие** (алиасы), чтобы менять палитру в одном месте:

```dart
static const Color btnBackground = primary;
static const Color fieldBorderFocused = primary;
```

Токены с **прозрачностью** задаются как `static Color` (не `const`), через `.withValues(alpha: …)`:

```dart
static Color bottomBarSegment = primary.withValues(alpha: 0.12);
static Color fieldShadowFocused = primary.withValues(alpha: 0.14);
```

### Как добавлять новый цвет

1. **Импорт** в виджете уже не нужен отдельно — файл лежит в `lib/core/resources/colors.dart`.
2. Выберите **слой** по смыслу (не кладите всё в `Misc`).
3. Добавьте константу в нужную секцию:

   ```dart
   static const Color myToken = Color(0xFF1A1D1E); // комментарий из Figma, если есть
   ```

4. **Именование:**
   - семантика, не «синий_3»: `surfaceMuted`, `fieldBorderFocused`, не `colorBlue2`;
   - для текста — `text*`, `subText*`, `textInverse`;
   - для фона — `surface*`, `bg*`, `pageBackground`;
   - для UI-компонента — префикс: `btn*`, `field*`, `bottomBar*`;
   - для одной фичи — префикс фичи: `postEditor*`.
5. Если цвет = уже существующий базовый — **алиас**, не дублируйте hex:

   ```dart
   static const Color cardTitle = textColor;
   ```

6. Нужна прозрачность в дизайн-системе — объявите `static Color` с `withValues`; в виджете можно ещё раз ослабить alpha при использовании.
7. Цвет **только для одного экрана** и нигде больше не повторится — допустимо в `Misc` или в блоке `// FEATURE NAME` внизу файла. Если появится второе использование — вынесите в общий слой.

Формат hex: `Color(0xFFRRGGBB)` (ARGB, альфа `FF` = непрозрачный).

### Как использовать в коде

```dart
import 'package:clover/core/resources/colors.dart';

// Фон, текст, обводка
Container(
  color: AppColors.surface,
  child: Text(
    'Заголовок',
    style: TextStyle(color: AppColors.textColor),
  ),
);

// Прозрачность поверх токена (тени, оверлеи, splash)
BoxDecoration(
  boxShadow: [
    BoxShadow(
      color: AppColors.shadowDark.withValues(alpha: 0.10),
      blurRadius: 12,
    ),
  ],
);

// Material-виджеты
Scaffold(
  backgroundColor: AppColors.pageBackground,
);

// Готовые токены компонентов — предпочтительнее «сырых» brand/surface
// AppField уже использует fieldBackground, fieldBorder, fieldHint и т.д.
// AppButton — primary, textInverse, borderCardGreen
```

**Правила:**

- `AppColors` — статический класс, `context` не нужен.
- Прозрачность: `.withValues(alpha: 0.0–1.0)` у цвета из `AppColors`, не `withOpacity` (deprecated).
- Для полей ввода и кнопок сначала смотрите токены `field*` / `btn*` / `bottomBar*` — не подставляйте `primary`/`border` вручную в каждом экране.
- Типографика: цвет текста передавайте в `AppTextStyle.base(..., color: AppColors.subTextColor)` (см. ниже).

### Чеклист перед PR

- [ ] В diff нет новых `Color(0x…)` вне `colors.dart`
- [ ] Новый токен в правильной секции и с понятным именем
- [ ] Повторяющийся hex вынесен в алиас, а не скопирован

---

## 2. Типографика — `style.dart` (`AppTextStyle`)

- Базовый текст: `AppTextStyle.base(...)`.
- Для любого текста используйте `AppTextStyle.base(...)` с нужным `fontSize`, `color`, `fontWeight`.
- Цвет всегда из `AppColors`, например: `AppTextStyle.base(16, color: AppColors.textColor)`.

## 3. Размеры из макета — `extension/context.dart`

- Значения в **пикселях Figma** передавайте в:

  - `context.heightByContext(value)` — высоты, вертикальные отступы, размер шрифта по вертикальной шкале;
  - `context.widthByContext(value)` — ширины, горизонтальные отступы, `BorderRadius` по ширине артборда.

- Константы артборда: `ContextExtension.designHeight` / `designWidth` — меняйте под свой макет один раз.

---

**Итог:** **цвета → `AppColors` (добавлять в `colors.dart`, использовать по имени токена), шрифты → `AppTextStyle`, числа из Figma → `heightByContext` / `widthByContext`.**
