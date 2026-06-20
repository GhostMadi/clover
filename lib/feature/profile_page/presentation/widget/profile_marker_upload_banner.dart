import 'package:clover/feature/marker_create/presentation/cubit/marker_create_upload_cubit.dart';
import 'package:clover/feature/marker_create/presentation/cubit/marker_create_upload_state.dart';
import 'package:clover/feature/profile_page/presentation/widget/profile_post_upload_progress.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProfileMarkerUploadBanner extends StatelessWidget {
  const ProfileMarkerUploadBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MarkerCreateUploadCubit, MarkerCreateUploadState>(
      builder: (context, state) {
        return switch (state) {
          MarkerCreateUploadIdle() => const SizedBox.shrink(),
          MarkerCreateUploadUploading(:final title, :final progress, :final thumbnailPath) =>
            ProfilePostUploadProgress(
              title: title,
              status: ProfilePostUploadStatus.uploading,
              progress: progress,
              localImagePath: thumbnailPath,
            ),
          MarkerCreateUploadSuccess(:final title, :final thumbnailPath) => ProfilePostUploadProgress(
            title: title,
            status: ProfilePostUploadStatus.success,
            localImagePath: thumbnailPath,
            successLabel: 'Маркер создан',
          ),
          MarkerCreateUploadFailure(:final title, :final thumbnailPath, :final message) =>
            ProfilePostUploadProgress(
              title: title,
              status: ProfilePostUploadStatus.failure,
              statusMessage: message,
              localImagePath: thumbnailPath,
              failureLabel: 'Не удалось создать маркер',
            ),
        };
      },
    );
  }
}
