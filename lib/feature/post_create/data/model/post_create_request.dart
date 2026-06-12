import 'dart:io';

import 'package:clover/core/post_media/post_media.dart';
import 'package:clover/core/shared/image_select/app_image_edit_settings.dart';

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

class PostCreateRequest {
  const PostCreateRequest({
    required this.title,
    required this.description,
    required this.media,
  });

  final String title;
  final String description;
  final List<PostCreateMediaInput> media;
}
