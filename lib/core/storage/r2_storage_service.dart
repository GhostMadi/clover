import 'dart:io';
import 'dart:typed_data';

import 'package:clover/core/network/supabase_edge_functions_invoker.dart';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';

/// Result of a successful R2 upload (single entry-point for all client media).
class R2UploadResult {
  const R2UploadResult({
    required this.fileKey,
    required this.publicUrl,
    required this.stablePublicUrl,
  });

  final String fileKey;

  /// Public URL with cache-bust query (good for avatars / covers in UI).
  final String publicUrl;

  /// Public URL without query (store in chat `public_url`, delete by URL).
  final String stablePublicUrl;
}

/// Direct upload/delete for Cloudflare R2 via Edge Functions.
///
/// All app media uploads should go through this service (not Supabase Storage).
@lazySingleton
class R2StorageService {
  R2StorageService(this._edge);

  final SupabaseEdgeFunctionsInvoker _edge;

  static const _uploadFn = 'get-upload-url';
  static const _deleteFn = 'delete-r2-objects';

  /// Reads [file], uploads to R2 under [folder], returns public URL (or `null` on failure).
  Future<String?> uploadFile(
    File file, {
    String folder = 'media',
    String? contentType,
  }) async {
    try {
      final result = await uploadFileDetailed(
        file,
        folder: folder,
        contentType: contentType,
      );
      return result?.publicUrl;
    } catch (_) {
      return null;
    }
  }

  Future<R2UploadResult?> uploadFileDetailed(
    File file, {
    String folder = 'media',
    String? contentType,
  }) async {
    try {
      if (!await file.exists()) return null;
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) return null;
      final name = _basename(file.path);
      final type = contentType?.trim().isNotEmpty == true
          ? contentType!.trim()
          : _guessContentType(name);
      return await uploadBytesDetailed(
        bytes,
        fileName: name,
        folder: folder,
        contentType: type,
      );
    } catch (_) {
      return null;
    }
  }

  /// Uploads raw bytes; throws on failure (for repositories).
  Future<String> uploadBytes(
    Uint8List bytes, {
    required String fileName,
    String folder = 'media',
    String contentType = 'application/octet-stream',
  }) async {
    final result = await uploadBytesDetailed(
      bytes,
      fileName: fileName,
      folder: folder,
      contentType: contentType,
    );
    return result.publicUrl;
  }

  Future<R2UploadResult> uploadBytesDetailed(
    Uint8List bytes, {
    required String fileName,
    String folder = 'media',
    String contentType = 'application/octet-stream',
  }) async {
    if (bytes.isEmpty) {
      throw StateError('Пустой файл для загрузки');
    }
    final name = fileName.trim();
    if (name.isEmpty) {
      throw StateError('Пустое имя файла');
    }
    final type = contentType.trim().isEmpty ? 'application/octet-stream' : contentType.trim();
    final folderSafe = folder.trim().isEmpty ? 'media' : folder.trim();

    final response = await _edge.invoke(
      _uploadFn,
      body: {
        'fileName': name,
        'fileType': type,
        'folder': folderSafe,
      },
    );

    final data = response.data;
    if (data is! Map) {
      throw StateError('Некорректный ответ get-upload-url');
    }
    final map = Map<String, dynamic>.from(data);
    final uploadUrl = (map['uploadUrl'] as String?)?.trim() ?? '';
    final publicUrl = (map['publicUrl'] as String?)?.trim() ?? '';
    final fileKey = (map['fileKey'] as String?)?.trim() ?? '';
    if (uploadUrl.isEmpty || publicUrl.isEmpty || fileKey.isEmpty) {
      throw StateError('get-upload-url не вернул uploadUrl/publicUrl/fileKey');
    }

    final put = await http.put(
      Uri.parse(uploadUrl),
      headers: {'Content-Type': type},
      body: bytes,
    );
    if (put.statusCode < 200 || put.statusCode >= 300) {
      throw StateError('R2 upload failed: HTTP ${put.statusCode}');
    }

    final sep = publicUrl.contains('?') ? '&' : '?';
    final busted = '$publicUrl${sep}v=${DateTime.now().millisecondsSinceEpoch}';
    return R2UploadResult(
      fileKey: fileKey,
      publicUrl: busted,
      stablePublicUrl: publicUrl,
    );
  }

  /// Best-effort delete of R2 objects owned by the current user (by public URL and/or key).
  Future<void> deleteObjects({
    Iterable<String>? urls,
    Iterable<String>? fileKeys,
  }) async {
    final urlList = [
      for (final u in urls ?? const <String>[])
        if (u.trim().isNotEmpty) u.trim().split('?').first,
    ];
    final keyList = [
      for (final k in fileKeys ?? const <String>[])
        if (k.trim().isNotEmpty) k.trim(),
    ];
    if (urlList.isEmpty && keyList.isEmpty) return;

    try {
      await _edge.invoke(
        _deleteFn,
        body: {
          if (urlList.isNotEmpty) 'urls': urlList,
          if (keyList.isNotEmpty) 'fileKeys': keyList,
        },
      );
    } catch (_) {
      // best effort — DB delete should still proceed
    }
  }

  static String _basename(String path) {
    final normalized = path.replaceAll('\\', '/');
    final i = normalized.lastIndexOf('/');
    return i >= 0 ? normalized.substring(i + 1) : normalized;
  }

  static String _guessContentType(String fileName) {
    final dot = fileName.lastIndexOf('.');
    final ext = dot >= 0 ? fileName.substring(dot).toLowerCase() : '';
    return switch (ext) {
      '.jpg' || '.jpeg' => 'image/jpeg',
      '.png' => 'image/png',
      '.webp' => 'image/webp',
      '.gif' => 'image/gif',
      '.mp4' => 'video/mp4',
      '.mov' => 'video/quicktime',
      '.pdf' => 'application/pdf',
      _ => 'application/octet-stream',
    };
  }
}
