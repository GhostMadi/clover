import 'dart:io';

import 'package:clover/feature/marker_create/data/model/marker_create_request.dart';
import 'package:clover/feature/marker_create/model/marker_create_compose_result.dart';

extension MarkerCreateComposeResultExtension on MarkerCreateComposeResult {
  String get displayTitle {
    final trimmed = title.trim();
    if (trimmed.isNotEmpty) return trimmed;

    final emoji = textEmoji.trim();
    if (emoji.isNotEmpty) return emoji;

    final address = location?.displayTitle.trim();
    if (address != null && address.isNotEmpty) return address;

    return 'Новый маркер';
  }

  File? get coverPreviewFile {
    if (media.isEmpty) return null;
    return media.first.previewFile;
  }

  MarkerCreateRequest toCreateRequest() {
    final selectedLocation = location;
    final period = eventPeriod;

    if (selectedLocation == null) {
      throw StateError('Не выбрано местоположение');
    }
    if (period == null) {
      throw StateError('Не выбран период события');
    }

    return MarkerCreateRequest(
      textEmoji: textEmoji.trim(),
      location: selectedLocation,
      eventPeriod: period,
      title: title.trim(),
      description: description.trim(),
      tagIds: tagIds,
      filterValues: filterValues,
      media: [
        for (var i = 0; i < media.length; i++)
          MarkerCreateMediaInput(
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
