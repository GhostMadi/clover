import 'dart:io';

import 'package:clover/core/shared/image_select/extension/app_image_editor_result_list_extension.dart';
import 'package:clover/feature/post_create/data/model/post_create_request.dart';
import 'package:clover/feature/post_create/model/post_create_compose_result.dart';

extension PostCreateComposeResultExtension on PostCreateComposeResult {
  String get displayTitle {
    final trimmed = title.trim();
    return trimmed.isNotEmpty ? trimmed : 'Новая публикация';
  }

  File? get coverPreviewFile {
    if (media.isEmpty) return null;
    return media.first.previewFile;
  }

  PostCreateRequest toCreateRequest() {
    return PostCreateRequest(
      title: title.trim(),
      description: description.trim(),
      filterValues: filterValues,
      media: [
        for (var i = 0; i < media.length; i++)
          PostCreateMediaInput(
            sourceFile: media[i].previewFile!,
            settings: media[i].settings,
            imageWidth: media[i].asset.width,
            imageHeight: media[i].asset.height,
            sortOrder: i,
          ),
      ],
    );
  }
}
