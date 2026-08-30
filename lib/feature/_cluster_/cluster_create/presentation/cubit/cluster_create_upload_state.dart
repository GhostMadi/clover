sealed class ClusterCreateUploadState {
  const ClusterCreateUploadState();
}

final class ClusterCreateUploadIdle extends ClusterCreateUploadState {
  const ClusterCreateUploadIdle();
}

final class ClusterCreateUploadUploading extends ClusterCreateUploadState {
  const ClusterCreateUploadUploading({
    required this.title,
    required this.progress,
    this.thumbnailPath,
  });

  final String title;
  final int progress;
  final String? thumbnailPath;
}

final class ClusterCreateUploadSuccess extends ClusterCreateUploadState {
  const ClusterCreateUploadSuccess({
    required this.title,
    required this.clusterId,
    this.thumbnailPath,
  });

  final String title;
  final String clusterId;
  final String? thumbnailPath;
}

final class ClusterCreateUploadFailure extends ClusterCreateUploadState {
  const ClusterCreateUploadFailure({
    required this.title,
    this.thumbnailPath,
    required this.message,
  });

  final String title;
  final String? thumbnailPath;
  final String message;
}
