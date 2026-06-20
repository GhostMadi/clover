import 'package:clover/core/shared/image_select/extension/app_image_editor_result_list_extension.dart';
import 'package:clover/feature/edit_profile/model/edit_profile_banner_draft.dart';

extension EditProfileBannerDraftExtension on EditProfileBannerDraft {
  bool get canOpenConfirm => hasSelection && editedMedia.isNotEmpty && editedMedia.allPreviewsReady;

  bool get canAccept => canOpenConfirm;
}
