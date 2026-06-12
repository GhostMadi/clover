/// Wrapper for persisting a local filesystem path (not the file bytes).
final class FilePathStorageValue {
  const FilePathStorageValue(this.path);

  final String path;
}
