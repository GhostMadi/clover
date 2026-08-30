import 'package:clover/core/shared/image_select/models/app_image_editor_result.dart';

class ClusterCreateComposeResult {
  const ClusterCreateComposeResult({
    required this.cover,
    required this.title,
    required this.description,
  });

  final AppImageEditorResult cover;
  final String title;
  final String description;
}
