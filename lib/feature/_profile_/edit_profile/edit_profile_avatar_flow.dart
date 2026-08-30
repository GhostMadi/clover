import 'package:clover/core/shared/image_select/models/app_image_editor_result.dart';
import 'package:clover/feature/_profile_/edit_profile/model/edit_profile_avatar_draft.dart';
import 'package:photo_manager/photo_manager.dart';

/// Данные между шагами смены аватара: выбор → редактор 1:1 → подтверждение.
class EditProfileAvatarFlow {
  EditProfileAvatarFlow._();

  static final EditProfileAvatarFlow instance = EditProfileAvatarFlow._();

  static const int maxPhotos = 1;

  EditProfileAvatarDraft _draft = const EditProfileAvatarDraft();
  AppImageEditorResult? _pendingResult;

  EditProfileAvatarDraft get draft => _draft;

  void saveSelection(List<AssetEntity> assets) {
    _draft = EditProfileAvatarDraft(
      selectedAssets: List.unmodifiable(assets.take(maxPhotos).toList()),
    );
  }

  void saveEditedMedia(List<AppImageEditorResult> media) {
    _draft = EditProfileAvatarDraft(
      selectedAssets: _draft.selectedAssets,
      editedMedia: List.unmodifiable(media.take(maxPhotos).toList()),
    );
  }

  void complete(AppImageEditorResult result) {
    _pendingResult = result;
    _draft = const EditProfileAvatarDraft();
  }

  AppImageEditorResult? consumeResult() {
    final result = _pendingResult;
    _pendingResult = null;
    return result;
  }

  void reset() {
    _draft = const EditProfileAvatarDraft();
    _pendingResult = null;
  }
}
