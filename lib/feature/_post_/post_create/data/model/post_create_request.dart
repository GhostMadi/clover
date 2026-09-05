import 'dart:io';

import 'package:clover/core/post_media/post_media.dart';
import 'package:clover/core/shared/app_time_picker.dart';
import 'package:clover/core/shared/image_select/app_image_edit_settings.dart';
import 'package:clover/feature/_catalog_/location/data/models/location_model.dart';

class PostCreateMediaInput {
  const PostCreateMediaInput({
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

/// Запрос на публикацию: обычный пост или ивент (если задан [eventPeriod]).
class PostCreateRequest {
  const PostCreateRequest({
    required this.title,
    required this.description,
    required this.textEmoji,
    required this.media,
    this.location,
    this.eventPeriod,
    this.tagIds = const {},
    this.filterValues = const {},
    this.bookingServiceId,
  });

  final String title;
  final String description;
  final String textEmoji;
  final LocationModel? location;
  final AppDateTimeRange? eventPeriod;
  final List<PostCreateMediaInput> media;
  final Set<String> tagIds;
  final Set<String> filterValues;
  final String? bookingServiceId;

  bool get isEvent => eventPeriod != null;
}

class PostCreateResult {
  const PostCreateResult({
    required this.postId,
    this.markerId,
  });

  final String postId;
  final String? markerId;
}
