import 'package:clover/core/shared/image_select/models/app_image_editor_result.dart';
import 'package:photo_manager/photo_manager.dart';

/// Снимок данных между шагами создания маркера.
class MarkerCreateDraft {
  const MarkerCreateDraft({
    this.selectedAssets = const [],
    this.editedMedia = const [],
  });

  final List<AssetEntity> selectedAssets;
  final List<AppImageEditorResult> editedMedia;

  bool get hasSelection => selectedAssets.isNotEmpty;

  bool get canOpenEditor => hasSelection;
}
