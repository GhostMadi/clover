import 'dart:io';

import 'package:clover/feature/_post_/post_create/data/model/post_create_request.dart';
import 'package:clover/feature/_post_/post_create/model/post_create_compose_result.dart';

extension PostCreateComposeResultExtension on PostCreateComposeResult {
  String get displayTitle {
    final trimmed = title.trim();
    if (trimmed.isNotEmpty) return trimmed;

    final emoji = textEmoji.trim();
    if (emoji.isNotEmpty) return emoji;

    final address = location?.displayTitle.trim();
    if (address != null && address.isNotEmpty) return address;

    return 'Новая публикация';
  }

  File? get coverPreviewFile {
    if (media.isEmpty) return null;
    return media.first.previewFile;
  }

  PostCreateRequest toPostCreateRequest() {
    if (media.isEmpty) {
      throw StateError('Нет медиа для публикации');
    }

    return PostCreateRequest(
      title: title.trim(),
      description: description.trim(),
      textEmoji: textEmoji.trim(),
      location: location,
      eventPeriod: eventPeriod,
      tagIds: tagIds,
      filterValues: filterValues,
      bookingServiceId: bookingServiceId?.trim().isEmpty == true ? null : bookingServiceId?.trim(),
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
