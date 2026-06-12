import 'package:clover/core/post_media/post_media.dart';
import 'package:clover/core/shared/image_select/models/app_image_editor_result.dart';

extension AppImageEditorResultExtension on AppImageEditorResult {
  bool get hasPreview => previewFile != null;
}

extension AppImageEditorResultListExtension on List<AppImageEditorResult> {
  bool get allPreviewsReady => isNotEmpty && every((item) => item.hasPreview);

  PostAspectRatio aspectRatioAt(int index) => this[index].settings.aspectRatio;

  double previewAspectRatioAt(int index) => aspectRatioAt(index).ratio;
}
