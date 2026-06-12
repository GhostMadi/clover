import 'package:clover/feature/post_create/data/repository/post_create_repository.dart';
import 'package:clover/feature/post_create/extension/post_create_compose_result_extension.dart';
import 'package:clover/feature/post_create/model/post_create_compose_result.dart';
import 'package:clover/feature/post_create/presentation/cubit/post_create_upload_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class PostCreateUploadCubit extends Cubit<PostCreateUploadState> {
  PostCreateUploadCubit(this._repository) : super(const PostCreateUploadIdle());

  final PostCreateRepository _repository;

  Future<void> publish(PostCreateComposeResult result) async {
    if (state is PostCreateUploadUploading) return;

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
      final postId = await _repository.createPost(
        request: result.toCreateRequest(),
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
}
