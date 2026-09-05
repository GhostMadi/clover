class ChatAttachmentUpload {
  const ChatAttachmentUpload({
    required this.bytes,
    required this.filename,
    required this.mime,
  });

  final List<int> bytes;
  final String filename;
  final String mime;
}
