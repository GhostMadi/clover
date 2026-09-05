# image_select

Переиспользуемый модуль выбора и редактирования фото. Не привязан к конкретной фиче — подключается через колбэки.

## Структура

```
image_select/
├── models/                         # DTO между экранами
│   ├── app_image_selector_result.dart
│   └── app_image_editor_result.dart
├── extension/                      # Вспомогательная логика
│   ├── asset_entity_list_extension.dart
│   └── app_image_editor_result_list_extension.dart
├── app_image_selector_page.dart    # Шаг 1: галерея
├── app_image_editor_page.dart      # Шаг 2: crop + эффекты
├── app_image_edit_preview.dart     # Статичное превью (без UI)
├── app_image_edit_settings.dart    # Настройки редактирования
└── app_image_crop_math.dart        # Математика crop/zoom
```

Форматы и размеры контейнеров поста — в `lib/core/post_media/post_media.dart` (`PostAspectRatio`, `PostMediaLayout`).

## Быстрый старт

### 1. Выбор фото

```dart
import 'package:clover/core/shared/image_select/app_image_selector_page.dart';

AppImageSelectorPage(
  title: 'Новая публикация',
  confirmLabel: 'Далее',
  maxSelectionCount: 15,
  onClose: () => Navigator.of(context).maybePop(),
  onConfirmed: (result) {
    // result.assets — List<AssetEntity>
  },
)
```

**Поведение:**
- только изображения (без видео);
- мультивыбор с номерами на плитках;
- превью сверху в формате `4:3`;
- счётчик в заголовке: `Новая публикация (2/15)`.

### 2. Редактирование

```dart
import 'package:clover/core/shared/image_select/app_image_editor_page.dart';

AppImageEditorPage(
  assets: selectedAssets,
  onClose: () => Navigator.of(context).maybePop(),
  onDone: (results) {
    // results — List<AppImageEditorResult>
  },
)
```

**Поведение:**
- вкладки: Настройка | Эффекты | Формат;
- pinch-zoom + pan для crop;
- несколько фото: полоска миниатюр, заголовок `Редактирование (2/5)`.

### 3. Превью без экрана

Когда нужно только отрисовать результат (например, финальный шаг публикации):

```dart
import 'package:clover/core/shared/image_select/app_image_edit_preview.dart';

AppImageEditPreview(
  imageFile: result.previewFile!,
  settings: result.settings,
  imageWidth: result.asset.width,
  imageHeight: result.asset.height,
  borderRadius: 16,
)
```

## Модели

| Класс | Поля | Когда использовать |
|-------|------|--------------------|
| `AppImageSelectorResult` | `assets` | После `AppImageSelectorPage` |
| `AppImageEditorResult` | `asset`, `settings`, `previewFile` | После `AppImageEditorPage` |
| `AppImageEditSettings` | яркость, эффект, `aspectRatio`, crop | Хранить на каждое фото |

## Extensions

### `AssetEntityListExtension`

```dart
import 'package:clover/core/shared/image_select/extension/asset_entity_list_extension.dart';

final files = await assets.loadFiles();
```

### `AppImageEditorResultListExtension`

```dart
import 'package:clover/core/shared/image_select/extension/app_image_editor_result_list_extension.dart';

if (results.allPreviewsReady) { ... }

final ratio = results.previewAspectRatioAt(0);
```

## Пример полного флоу

Реализация создания поста: `lib/feature/_post_/post_create/` (`PostCreateRepository.publish`).

```dart
// Шаг 1 — выбор
flow.saveSelection(result.assets);
router.pushPostCreateEditor();

// Шаг 2 — редактор
flow.saveEditedMedia(results);
router.pushPostCreateCompose();

// Шаг 3 — заголовок + описание
// media: flow.draft.editedMedia
flow.reset();
router.closePostCreateFlow();
```

Навигация и состояние между шагами вынесены в:
- `PostCreateFlow` — immutable `PostCreateDraft`;
- `PostCreateRouterExtension` — `pushPostCreateEditor`, `closePostCreateFlow`;
- `PostCreateStepGuard` — возврат назад, если шаг открыт без данных.

## iOS

В `Info.plist` должны быть ключи:
- `NSPhotoLibraryUsageDescription`
- `NSPhotoLibraryAddUsageDescription`

## Зависимости

- `photo_manager` — доступ к галерее;
- `photo_manager_image_provider` — превью в сетке.
