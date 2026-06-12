import 'dart:io';

import 'package:clover/core/shared/image_select/app_image_edit_settings.dart';
import 'package:photo_manager/photo_manager.dart';

/// Результат редактирования одного фото.
class AppImageEditorResult {
  const AppImageEditorResult({
    required this.asset,
    required this.settings,
    this.previewFile,
  });

  final AssetEntity asset;
  final AppImageEditSettings settings;
  final File? previewFile;
}
