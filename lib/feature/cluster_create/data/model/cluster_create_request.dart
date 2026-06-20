import 'dart:io';

import 'package:clover/core/shared/image_select/app_image_edit_settings.dart';

class ClusterCreateRequest {
  const ClusterCreateRequest({
    required this.title,
    required this.subtitle,
    required this.cover,
  });

  final String title;
  final String subtitle;
  final ClusterCreateCoverInput cover;
}

class ClusterCreateCoverInput {
  const ClusterCreateCoverInput({
    required this.sourceFile,
    required this.settings,
    required this.imageWidth,
    required this.imageHeight,
  });

  final File sourceFile;
  final AppImageEditSettings settings;
  final int imageWidth;
  final int imageHeight;
}
