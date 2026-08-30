import 'package:clover/core/shared/image_select/extension/app_image_editor_result_list_extension.dart';
import 'package:clover/feature/_cluster_/cluster_create/model/cluster_create_draft.dart';

extension ClusterCreateDraftExtension on ClusterCreateDraft {
  bool get canOpenCompose => hasSelection && editedMedia.isNotEmpty && editedMedia.allPreviewsReady;

  bool get canPublish => canOpenCompose;
}
