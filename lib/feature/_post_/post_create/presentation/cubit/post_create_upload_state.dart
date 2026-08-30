sealed class PostCreateUploadState {
  const PostCreateUploadState();
}

final class PostCreateUploadIdle extends PostCreateUploadState {
  const PostCreateUploadIdle();
}

final class PostCreateUploadUploading extends PostCreateUploadState {
  const PostCreateUploadUploading({
    required this.title,
    required this.progress,
    this.thumbnailPath,
  });

  final String title;
  final int progress;
  final String? thumbnailPath;
}

final class PostCreateUploadSuccess extends PostCreateUploadState {
  const PostCreateUploadSuccess({
    required this.title,
    required this.postId,
    this.thumbnailPath,
  });

  final String title;
  final String postId;
  final String? thumbnailPath;
}

final class PostCreateUploadFailure extends PostCreateUploadState {
  const PostCreateUploadFailure({
    required this.title,
    this.thumbnailPath,
    required this.message,
  });

  final String title;
  final String? thumbnailPath;
  final String message;
}
