# Adaptive widgets (нативность + тема)

**Статус:** правило UI-фундамента  
**Код:** `lib/core/shared/platform/`  
**Правила Cursor:** `clover-widgets`, `clover-resources`, `clover-design`

---

## Цель

1. Всё продуктовое и техническое важное — **через документацию** (`docs/business/`, `docs/code/`, `docs/supabase/`), потом код.
2. UI-кирпичи — **переиспользуемые** (`core/shared`), чтобы менять вид/поведение в одном месте.
3. При создании виджета **сразу**:
   - прививать **тему** (`context.colors` / `AppPalette`);
   - прививать **нативный визуал** iOS (Cupertino) и Android (Material).

Фича не должна изобретать свою кнопку / switch / sheet — только собирать из shared.

---

## Порядок создания UI

1. Нужен ли новый **продуктовый** сценарий? → `docs/business/`
2. Нужен ли новый **shared-виджет**? → кратко здесь или в `docs/code/ui/`, затем код в `core/shared`
3. Ресурс (цвет / стиль / иконка / строка) → `core/resources` (+ theme)
4. Виджет:
   - shared с нативным split → `AdaptiveStatelessWidget`
   - иконка → пара android/ios в `AppIcons`
5. Фича только композит: page + widgets поверх shared

---

## Каркас кода

```dart
class AppExample extends AdaptiveStatelessWidget {
  const AppExample({super.key});

  @override
  Widget buildMaterial(BuildContext context, AppPalette colors) {
    // Material / Android — цвета из colors.*
  }

  @override
  Widget buildCupertino(BuildContext context, AppPalette colors) {
    // Cupertino / iOS — цвета из colors.*
  }
}
```

Платформа: `AppPlatform.current` / `context.isIOS` (не `dart:io`).

Sheet: только `AppBottomSheet.show` (см. `clover-bottom-sheet`).

---

## Что уже «нативно» частично

| Область | Сейчас | Цель |
|---------|--------|------|
| Иконки | `AppIcons` android/ios | оставить; детект через `AppPlatform` |
| Switch | `Switch.adaptive` + `AdaptiveStatelessWidget` | Cupertino split при необходимости |
| Button / dialog / field | в основном единый Material-look | постепенно Material vs Cupertino при правках |
| Shimmer / refresh / switch row | `AdaptiveStatelessWidget` (каркас готов) | нативный split по мере правок |
| Bottom sheet | единый `AppBottomSheet` | API один; внутренности можно адаптировать позже |

Новые shared-виджеты — **сразу** через `AdaptiveStatelessWidget`, без «потом допилим нативность».

---

## Запрещено

- Хардкод `Colors.*` / hex / сырой `TextStyle` / сырые `Icons.*` в фичах
- Дублировать кнопку/инпут внутри фичи вместо shared
- Создавать shared без темы (только статичные `AppColors.primary` без `of(context)` там, где нужен light/dark rebuild)
- Сразу `showModalBottomSheet` в фиче
