import 'package:clover/core/shared/image_select/models/app_image_editor_result.dart';
import 'package:clover/feature/post_create/model/post_create_draft.dart';
import 'package:photo_manager/photo_manager.dart';

/// Хранит данные между шагами: выбор → редактор → публикация.
class PostCreateFlow {
  PostCreateFlow._();

  static final PostCreateFlow instance = PostCreateFlow._();

  static const int maxPhotos = 15;

  PostCreateDraft _draft = const PostCreateDraft();

  PostCreateDraft get draft => _draft;

  void saveSelection(List<AssetEntity> assets) {
    _draft = PostCreateDraft(selectedAssets: List.unmodifiable(assets));
  }

  void saveEditedMedia(List<AppImageEditorResult> media) {
    _draft = PostCreateDraft(selectedAssets: _draft.selectedAssets, editedMedia: List.unmodifiable(media));
  }

  void reset() {
    _draft = const PostCreateDraft();
  }
}
