import 'package:clover/feature/_post_/post_create/presentation/cubit/post_create_upload_cubit.dart';
import 'package:clover/feature/_post_/post_create/presentation/cubit/post_create_upload_state.dart';
import 'package:clover/feature/_profile_/profile_page/presentation/widget/profile_post_upload_progress.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProfilePostUploadBanner extends StatelessWidget {
  const ProfilePostUploadBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PostCreateUploadCubit, PostCreateUploadState>(
      builder: (context, state) {
        return switch (state) {
          PostCreateUploadIdle() => const SizedBox.shrink(),
          PostCreateUploadUploading(:final title, :final progress, :final thumbnailPath) =>
            ProfilePostUploadProgress(
              title: title,
              status: ProfilePostUploadStatus.uploading,
              progress: progress,
              localImagePath: thumbnailPath,
            ),
          PostCreateUploadSuccess(:final title, :final thumbnailPath) => ProfilePostUploadProgress(
            title: title,
            status: ProfilePostUploadStatus.success,
            localImagePath: thumbnailPath,
          ),
          PostCreateUploadFailure(:final title, :final thumbnailPath, :final message) =>
            ProfilePostUploadProgress(
              title: title,
              status: ProfilePostUploadStatus.failure,
              statusMessage: message,
              localImagePath: thumbnailPath,
            ),
        };
      },
    );
  }
}
