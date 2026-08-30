import 'package:clover/core/shared/image_select/models/app_image_editor_result.dart';
import 'package:clover/feature/_cluster_/cluster_create/model/cluster_create_draft.dart';
import 'package:photo_manager/photo_manager.dart';

/// Данные между шагами: выбор → редактор → название/описание.
class ClusterCreateFlow {
  ClusterCreateFlow._();

  static final ClusterCreateFlow instance = ClusterCreateFlow._();

  static const int maxPhotos = 1;

  ClusterCreateDraft _draft = const ClusterCreateDraft();

  ClusterCreateDraft get draft => _draft;

  void saveSelection(List<AssetEntity> assets) {
    _draft = ClusterCreateDraft(selectedAssets: List.unmodifiable(assets.take(maxPhotos).toList()));
  }

  void saveEditedMedia(List<AppImageEditorResult> media) {
    _draft = ClusterCreateDraft(
      selectedAssets: _draft.selectedAssets,
      editedMedia: List.unmodifiable(media.take(maxPhotos).toList()),
    );
  }

  void reset() {
    _draft = const ClusterCreateDraft();
  }
}
