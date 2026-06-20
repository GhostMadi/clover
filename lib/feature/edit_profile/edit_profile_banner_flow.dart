import 'package:clover/core/shared/image_select/models/app_image_editor_result.dart';
import 'package:clover/feature/edit_profile/model/edit_profile_banner_draft.dart';
import 'package:photo_manager/photo_manager.dart';

/// Данные между шагами смены обложки профиля: выбор → редактор 16:9 → подтверждение.
class EditProfileBannerFlow {
  EditProfileBannerFlow._();

  static final EditProfileBannerFlow instance = EditProfileBannerFlow._();

  static const int maxPhotos = 1;

  EditProfileBannerDraft _draft = const EditProfileBannerDraft();
  AppImageEditorResult? _pendingResult;

  EditProfileBannerDraft get draft => _draft;

  void saveSelection(List<AssetEntity> assets) {
    _draft = EditProfileBannerDraft(
      selectedAssets: List.unmodifiable(assets.take(maxPhotos).toList()),
    );
  }

  void saveEditedMedia(List<AppImageEditorResult> media) {
    _draft = EditProfileBannerDraft(
      selectedAssets: _draft.selectedAssets,
      editedMedia: List.unmodifiable(media.take(maxPhotos).toList()),
    );
  }

  void complete(AppImageEditorResult result) {
    _pendingResult = result;
    _draft = const EditProfileBannerDraft();
  }

  AppImageEditorResult? consumeResult() {
    final result = _pendingResult;
    _pendingResult = null;
    return result;
  }

  void reset() {
    _draft = const EditProfileBannerDraft();
    _pendingResult = null;
  }
}
