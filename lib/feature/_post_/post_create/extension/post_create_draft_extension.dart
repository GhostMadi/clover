import 'package:clover/core/shared/image_select/extension/app_image_editor_result_list_extension.dart';
import 'package:clover/feature/_post_/post_create/model/post_create_draft.dart';

extension PostCreateDraftExtension on PostCreateDraft {
  bool get canOpenCompose => hasSelection && editedMedia.allPreviewsReady;

  bool get canPublish => canOpenCompose;
}
