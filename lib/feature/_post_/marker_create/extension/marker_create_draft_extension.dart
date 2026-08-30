import 'package:clover/core/shared/image_select/extension/app_image_editor_result_list_extension.dart';
import 'package:clover/feature/_post_/marker_create/model/marker_create_draft.dart';

extension MarkerCreateDraftExtension on MarkerCreateDraft {
  bool get canOpenCompose => hasSelection && editedMedia.allPreviewsReady;

  bool get canPublish => canOpenCompose;
}
