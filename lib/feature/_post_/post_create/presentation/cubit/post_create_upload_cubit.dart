import 'package:clover/feature/_post_/marker_create/data/repository/marker_create_repository.dart';
import 'package:clover/feature/_post_/post_create/data/repository/post_create_repository.dart';
import 'package:clover/feature/_post_/post_create/extension/post_create_compose_result_extension.dart';
import 'package:clover/feature/_post_/post_create/extension/post_create_compose_validation.dart';
import 'package:clover/feature/_post_/post_create/model/post_create_compose_result.dart';
import 'package:clover/feature/_post_/post_create/presentation/cubit/post_create_upload_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class PostCreateUploadCubit extends Cubit<PostCreateUploadState> {
  PostCreateUploadCubit(this._markerRepository, this._postRepository) : super(const PostCreateUploadIdle());

  final MarkerCreateRepository _markerRepository;
  final PostCreateRepository _postRepository;

  Future<void> publish(PostCreateComposeResult result) async {
    if (state is PostCreateUploadUploading) return;

    final blockReason = result.publishBlockReason;
    if (blockReason != null) {
      throw StateError(blockReason);
    }

    final title = result.displayTitle;
    final thumbnailPath = result.coverPreviewFile?.path;

    emit(
      PostCreateUploadUploading(
        title: title,
        progress: 0,
        thumbnailPath: thumbnailPath,
      ),
    );

    try {
      final postId = result.isEvent
          ? await _publishEvent(result, title, thumbnailPath)
          : await _publishPostOnly(result, title, thumbnailPath);

      if (isClosed) return;
      emit(
        PostCreateUploadSuccess(
          title: title,
          postId: postId,
          thumbnailPath: thumbnailPath,
        ),
      );
    } catch (error) {
      if (isClosed) return;
      emit(
        PostCreateUploadFailure(
          title: title,
          thumbnailPath: thumbnailPath,
          message: '$error',
        ),
      );
    }
  }

  Future<String> _publishEvent(
    PostCreateComposeResult result,
    String title,
    String? thumbnailPath,
  ) async {
    final response = await _markerRepository.createMarker(
      request: result.toMarkerCreateRequest(),
      onProgress: (progress) {
        if (isClosed) return;
        emit(
          PostCreateUploadUploading(
            title: title,
            progress: progress,
            thumbnailPath: thumbnailPath,
          ),
        );
      },
    );
    return response.postId;
  }

  Future<String> _publishPostOnly(
    PostCreateComposeResult result,
    String title,
    String? thumbnailPath,
  ) async {
    return _postRepository.createPost(
      request: result.toPostCreateRequest(),
      onProgress: (progress) {
        if (isClosed) return;
        emit(
          PostCreateUploadUploading(
            title: title,
            progress: progress,
            thumbnailPath: thumbnailPath,
          ),
        );
      },
    );
  }

  void reset() {
    if (state is PostCreateUploadUploading) return;
    emit(const PostCreateUploadIdle());
  }
}
