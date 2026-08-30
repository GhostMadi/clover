import 'dart:io';

import 'package:clover/core/post_media/post_media.dart';
import 'package:clover/core/shared/app_time_picker.dart';
import 'package:clover/core/shared/image_select/app_image_edit_settings.dart';
import 'package:clover/feature/_catalog_/location/data/models/location_model.dart';

class MarkerCreateMediaInput {
  const MarkerCreateMediaInput({
    required this.sourceFile,
    required this.settings,
    required this.imageWidth,
    required this.imageHeight,
    required this.sortOrder,
  });

  final File sourceFile;
  final AppImageEditSettings settings;
  final int imageWidth;
  final int imageHeight;
  final int sortOrder;

  PostAspectRatio get aspectRatio => settings.aspectRatio;
}

class MarkerCreateRequest {
  const MarkerCreateRequest({
    required this.textEmoji,
    required this.location,
    required this.eventPeriod,
    required this.title,
    required this.description,
    required this.media,
    this.tagIds = const {},
    this.filterValues = const {},
  });

  final String textEmoji;
  final LocationModel location;
  final AppDateTimeRange eventPeriod;
  final String title;
  final String description;
  final List<MarkerCreateMediaInput> media;
  final Set<String> tagIds;
  final Set<String> filterValues;

  Duration get duration => eventPeriod.duration;

  DateTime get eventTime => eventPeriod.start;
}

class MarkerCreateResponse {
  const MarkerCreateResponse({
    required this.markerId,
    required this.postId,
  });

  final String markerId;
  final String postId;
}
