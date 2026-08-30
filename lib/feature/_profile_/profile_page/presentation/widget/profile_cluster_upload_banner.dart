import 'package:clover/feature/_cluster_/cluster_create/presentation/cubit/cluster_create_upload_cubit.dart';
import 'package:clover/feature/_cluster_/cluster_create/presentation/cubit/cluster_create_upload_state.dart';
import 'package:clover/feature/_profile_/profile_page/presentation/widget/profile_post_upload_progress.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProfileClusterUploadBanner extends StatelessWidget {
  const ProfileClusterUploadBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ClusterCreateUploadCubit, ClusterCreateUploadState>(
      builder: (context, state) {
        return switch (state) {
          ClusterCreateUploadIdle() => const SizedBox.shrink(),
          ClusterCreateUploadUploading(:final title, :final progress, :final thumbnailPath) =>
            ProfilePostUploadProgress(
              title: title,
              status: ProfilePostUploadStatus.uploading,
              progress: progress,
              localImagePath: thumbnailPath,
              successLabel: 'Кластер создан',
              failureLabel: 'Не удалось создать кластер',
            ),
          ClusterCreateUploadSuccess(:final title, :final thumbnailPath) => ProfilePostUploadProgress(
            title: title,
            status: ProfilePostUploadStatus.success,
            localImagePath: thumbnailPath,
            successLabel: 'Кластер создан',
            failureLabel: 'Не удалось создать кластер',
          ),
          ClusterCreateUploadFailure(:final title, :final thumbnailPath, :final message) =>
            ProfilePostUploadProgress(
              title: title,
              status: ProfilePostUploadStatus.failure,
              statusMessage: message,
              localImagePath: thumbnailPath,
              successLabel: 'Кластер создан',
              failureLabel: 'Не удалось создать кластер',
            ),
        };
      },
    );
  }
}
