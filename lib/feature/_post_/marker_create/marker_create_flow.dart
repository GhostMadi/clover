import 'package:clover/core/shared/image_select/models/app_image_editor_result.dart';
import 'package:clover/feature/marker_create/model/marker_create_draft.dart';
import 'package:photo_manager/photo_manager.dart';

/// Хранит данные между шагами: выбор → редактор → публикация маркера.
class MarkerCreateFlow {
  MarkerCreateFlow._();

  static final MarkerCreateFlow instance = MarkerCreateFlow._();

  static const int maxPhotos = 15;

  MarkerCreateDraft _draft = const MarkerCreateDraft();

  MarkerCreateDraft get draft => _draft;

  void saveSelection(List<AssetEntity> assets) {
    _draft = MarkerCreateDraft(selectedAssets: List.unmodifiable(assets));
  }

  void saveEditedMedia(List<AppImageEditorResult> media) {
    _draft = MarkerCreateDraft(selectedAssets: _draft.selectedAssets, editedMedia: List.unmodifiable(media));
  }

  void reset() {
    _draft = const MarkerCreateDraft();
  }
}
