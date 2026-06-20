import 'package:clover/feature/marker_create/data/repository/marker_create_repository.dart';
import 'package:clover/feature/marker_create/extension/marker_create_compose_result_extension.dart';
import 'package:clover/feature/marker_create/model/marker_create_compose_result.dart';
import 'package:clover/feature/marker_create/presentation/cubit/marker_create_upload_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class MarkerCreateUploadCubit extends Cubit<MarkerCreateUploadState> {
  MarkerCreateUploadCubit(this._repository) : super(const MarkerCreateUploadIdle());

  final MarkerCreateRepository _repository;

  Future<void> publish(MarkerCreateComposeResult result) async {
    if (state is MarkerCreateUploadUploading) return;

    final title = result.displayTitle;
    final thumbnailPath = result.coverPreviewFile?.path;

    emit(
      MarkerCreateUploadUploading(
        title: title,
        progress: 0,
        thumbnailPath: thumbnailPath,
      ),
    );

    try {
      final response = await _repository.createMarker(
        request: result.toCreateRequest(),
        onProgress: (progress) {
          if (isClosed) return;
          emit(
            MarkerCreateUploadUploading(
              title: title,
              progress: progress,
              thumbnailPath: thumbnailPath,
            ),
          );
        },
      );

      if (isClosed) return;
      emit(
        MarkerCreateUploadSuccess(
          title: title,
          markerId: response.markerId,
          thumbnailPath: thumbnailPath,
        ),
      );
    } catch (error) {
      if (isClosed) return;
      emit(
        MarkerCreateUploadFailure(
          title: title,
          thumbnailPath: thumbnailPath,
          message: '$error',
        ),
      );
    }
  }
}
