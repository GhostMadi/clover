import 'dart:typed_data';

import 'package:clover/feature/_chat_/chat/data/models/chat_attachment_upload.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

/// Сжатие фото перед отправкой в чат (ориентир — Instagram feed).
abstract final class ChatImageCompress {
  /// Длинная сторона ≈ feed Instagram.
  static const int maxSide = 1080;

  /// JPEG quality ~ Instagram (не максимальный).
  static const int jpegQuality = 78;

  static Future<ChatAttachmentUpload> prepareUpload({
    required List<int> bytes,
    required String filename,
  }) async {
    if (bytes.isEmpty) {
      return ChatAttachmentUpload(
        bytes: bytes,
        filename: _jpegFilename(filename),
        mime: 'image/jpeg',
      );
    }

    try {
      final compressed = await FlutterImageCompress.compressWithList(
        Uint8List.fromList(bytes),
        minWidth: maxSide,
        minHeight: maxSide,
        quality: jpegQuality,
        format: CompressFormat.jpeg,
        keepExif: false,
      );

      if (compressed.isNotEmpty) {
        return ChatAttachmentUpload(
          bytes: compressed,
          filename: _jpegFilename(filename),
          mime: 'image/jpeg',
        );
      }
    } catch (_) {
      // fallback to original below
    }

    return ChatAttachmentUpload(
      bytes: bytes,
      filename: filename,
      mime: _mimeFromFilename(filename),
    );
  }

  static String _jpegFilename(String filename) {
    final trimmed = filename.trim();
    final dot = trimmed.lastIndexOf('.');
    final base = (dot > 0 ? trimmed.substring(0, dot) : trimmed).trim();
    final safe = base.isEmpty ? 'photo' : base;
    return '$safe.jpg';
  }

  static String _mimeFromFilename(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.heic')) return 'image/heic';
    return 'image/jpeg';
  }
}
