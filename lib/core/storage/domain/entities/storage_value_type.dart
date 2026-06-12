/// Discriminator stored alongside each [StorageItem] value for safe deserialization.
enum StorageValueType {
  string,
  int,
  bool,
  double,

  /// Single object serialized as JSON (`Map<String, dynamic>`).
  jsonObject,

  /// List serialized as JSON (`List<dynamic>`).
  jsonList,

  /// Local file path (images, documents). Prefer paths over raw bytes for offline-first apps.
  filePath,
}
