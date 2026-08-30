import 'package:clover/core/shared/image_select/extension/app_image_editor_result_list_extension.dart';
import 'package:clover/feature/_profile_/edit_profile/model/edit_profile_avatar_draft.dart';

extension EditProfileAvatarDraftExtension on EditProfileAvatarDraft {
  bool get canOpenConfirm => hasSelection && editedMedia.isNotEmpty && editedMedia.allPreviewsReady;

  bool get canAccept => canOpenConfirm;
}
