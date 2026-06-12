import 'package:clover/core/shared/image_select/models/app_image_editor_result.dart';

/// Итоговые данные перед отправкой поста на сервер.
class PostCreateComposeResult {
  const PostCreateComposeResult({
    required this.media,
    required this.title,
    required this.description,
  });

  final List<AppImageEditorResult> media;
  final String title;
  final String description;
}
