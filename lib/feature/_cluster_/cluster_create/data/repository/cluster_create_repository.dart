import 'package:clover/core/shared/image_select/app_image_edit_exporter.dart';
import 'package:clover/feature/_cluster_/cluster/data/repository/cluster_repository.dart';
import 'package:clover/feature/_cluster_/cluster_create/data/model/cluster_create_request.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:injectable/injectable.dart';

abstract class ClusterCreateRepository {
  Future<String> createCluster({
    required ClusterCreateRequest request,
    ValueChanged<int>? onProgress,
  });
}

@LazySingleton(as: ClusterCreateRepository)
class ClusterCreateRepositoryImpl implements ClusterCreateRepository {
  ClusterCreateRepositoryImpl(this._clusters);

  final ClusterRepository _clusters;

  @override
  Future<String> createCluster({
    required ClusterCreateRequest request,
    ValueChanged<int>? onProgress,
  }) async {
    void report(int value) => onProgress?.call(value.clamp(0, 100));

    report(8);

    final cover = request.cover;
    final bytes = await AppImageEditExporter.exportJpegBytes(
      sourceFile: cover.sourceFile,
      settings: cover.settings,
      imageWidth: cover.imageWidth,
      imageHeight: cover.imageHeight,
    );
    final compressed = await FlutterImageCompress.compressWithList(bytes, quality: 88);

    report(45);

    final cluster = await _clusters.createCluster(
      title: request.title,
      subtitle: request.subtitle.isEmpty ? null : request.subtitle,
      coverBytes: compressed,
    );

    report(100);
    return cluster.id;
  }
}
