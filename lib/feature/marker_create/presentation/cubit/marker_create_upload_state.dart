sealed class MarkerCreateUploadState {
  const MarkerCreateUploadState();
}

final class MarkerCreateUploadIdle extends MarkerCreateUploadState {
  const MarkerCreateUploadIdle();
}

final class MarkerCreateUploadUploading extends MarkerCreateUploadState {
  const MarkerCreateUploadUploading({
    required this.title,
    required this.progress,
    this.thumbnailPath,
  });

  final String title;
  final int progress;
  final String? thumbnailPath;
}

final class MarkerCreateUploadSuccess extends MarkerCreateUploadState {
  const MarkerCreateUploadSuccess({
    required this.title,
    required this.markerId,
    this.thumbnailPath,
  });

  final String title;
  final String markerId;
  final String? thumbnailPath;
}

final class MarkerCreateUploadFailure extends MarkerCreateUploadState {
  const MarkerCreateUploadFailure({
    required this.title,
    this.thumbnailPath,
    required this.message,
  });

  final String title;
  final String? thumbnailPath;
  final String message;
}
