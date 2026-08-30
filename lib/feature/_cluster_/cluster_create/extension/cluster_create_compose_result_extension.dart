import 'dart:io';

import 'package:clover/feature/_cluster_/cluster_create/data/model/cluster_create_request.dart';
import 'package:clover/feature/_cluster_/cluster_create/model/cluster_create_compose_result.dart';

extension ClusterCreateComposeResultExtension on ClusterCreateComposeResult {
  String get displayTitle {
    final trimmed = title.trim();
    return trimmed.isNotEmpty ? trimmed : 'Новый кластер';
  }

  File? get coverPreviewFile => cover.previewFile;

  bool get isValid => title.trim().isNotEmpty;

  ClusterCreateRequest toCreateRequest() {
    final item = cover;
    return ClusterCreateRequest(
      title: title.trim(),
      subtitle: description.trim(),
      cover: ClusterCreateCoverInput(
        sourceFile: item.previewFile!,
        settings: item.settings,
        imageWidth: item.asset.width,
        imageHeight: item.asset.height,
      ),
    );
  }
}
