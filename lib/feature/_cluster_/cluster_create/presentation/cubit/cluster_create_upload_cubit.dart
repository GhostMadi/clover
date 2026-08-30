import 'package:clover/feature/_cluster_/cluster_create/data/repository/cluster_create_repository.dart';
import 'package:clover/feature/_cluster_/cluster_create/extension/cluster_create_compose_result_extension.dart';
import 'package:clover/feature/_cluster_/cluster_create/model/cluster_create_compose_result.dart';
import 'package:clover/feature/_cluster_/cluster_create/presentation/cubit/cluster_create_upload_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class ClusterCreateUploadCubit extends Cubit<ClusterCreateUploadState> {
  ClusterCreateUploadCubit(this._repository) : super(const ClusterCreateUploadIdle());

  final ClusterCreateRepository _repository;

  Future<void> publish(ClusterCreateComposeResult result) async {
    if (state is ClusterCreateUploadUploading) return;
    if (!result.isValid) return;

    final title = result.displayTitle;
    final thumbnailPath = result.coverPreviewFile?.path;

    emit(
      ClusterCreateUploadUploading(
        title: title,
        progress: 0,
        thumbnailPath: thumbnailPath,
      ),
    );

    try {
      final clusterId = await _repository.createCluster(
        request: result.toCreateRequest(),
        onProgress: (progress) {
          if (isClosed) return;
          emit(
            ClusterCreateUploadUploading(
              title: title,
              progress: progress,
              thumbnailPath: thumbnailPath,
            ),
          );
        },
      );

      if (isClosed) return;
      emit(
        ClusterCreateUploadSuccess(
          title: title,
          clusterId: clusterId,
          thumbnailPath: thumbnailPath,
        ),
      );
    } catch (error) {
      if (isClosed) return;
      emit(
        ClusterCreateUploadFailure(
          title: title,
          thumbnailPath: thumbnailPath,
          message: '$error',
        ),
      );
    }
  }

  void reset() {
    if (state is ClusterCreateUploadUploading) return;
    emit(const ClusterCreateUploadIdle());
  }
}
