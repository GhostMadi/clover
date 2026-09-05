class ChatMessageAttachment {
  const ChatMessageAttachment({
    required this.id,
    required this.bucket,
    required this.path,
    this.mime,
    this.sizeBytes,
    this.url,
  });

  final String id;
  final String bucket;
  final String path;
  final String? mime;
  final int? sizeBytes;
  final String? url;

  bool get isImage {
    final value = mime?.toLowerCase().trim();
    if (value == null || value.isEmpty) return false;
    return value.startsWith('image/');
  }

  String get displayName {
    final segments = path.split('/');
    final raw = segments.isNotEmpty ? segments.last : path;
    return raw.isNotEmpty ? raw : 'Файл';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bucket': bucket,
      'path': path,
      if (mime != null) 'mime': mime,
      if (sizeBytes != null) 'size_bytes': sizeBytes,
      if (url != null) 'url': url,
    };
  }

  factory ChatMessageAttachment.fromJson(Map<String, dynamic> json) {
    return ChatMessageAttachment(
      id: (json['id'] as String?)?.trim() ?? '',
      bucket: (json['bucket'] as String?)?.trim() ?? 'chat_media',
      path: (json['path'] as String?)?.trim() ?? '',
      mime: (json['mime'] as String?)?.trim(),
      sizeBytes: (json['size_bytes'] as num?)?.toInt(),
      url: (json['url'] as String?)?.trim(),
    );
  }
}
