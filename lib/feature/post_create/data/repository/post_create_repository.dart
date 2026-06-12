import 'dart:math';

import 'package:clover/core/shared/image_select/app_image_edit_exporter.dart';
import 'package:clover/feature/post_create/data/model/post_create_request.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class PostCreateRepository {
  Future<String> createPost({
    required PostCreateRequest request,
    ValueChanged<int>? onProgress,
  });
}

@LazySingleton(as: PostCreateRepository)
class PostCreateRepositoryImpl implements PostCreateRepository {
  PostCreateRepositoryImpl(this._client);

  final SupabaseClient _client;

  static const _bucketPostMedia = 'post_media';

  @override
  Future<String> createPost({
    required PostCreateRequest request,
    ValueChanged<int>? onProgress,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      throw StateError('Нет сессии: войдите в аккаунт');
    }
    if (request.media.isEmpty) {
      throw ArgumentError('Нужно хотя бы одно фото');
    }

    void report(int value) => onProgress?.call(value.clamp(0, 100));

    report(5);

    final postRow = await _client
        .from('posts')
        .insert({
          'user_id': uid,
          'title': request.title.isEmpty ? null : request.title,
          'description': request.description.isEmpty ? null : request.description,
        })
        .select('id')
        .single();

    final postId = (postRow['id'] as String?)?.trim();
    if (postId == null || postId.isEmpty) {
      throw StateError('Не удалось создать пост');
    }

    report(12);

    final uploadedPaths = <String>[];

    try {
      final mediaRows = <Map<String, dynamic>>[];
      final total = request.media.length;
      final uploadSpan = 78;

      for (var i = 0; i < total; i++) {
        final item = request.media[i];
        final mediaId = _newMediaId();
        final fileName = '$mediaId${item.aspectRatio.storageMarker}.jpg';
        final storagePath = 'posts/$postId/$fileName';

        final bytes = await AppImageEditExporter.exportJpegBytes(
          sourceFile: item.sourceFile,
          settings: item.settings,
          imageWidth: item.imageWidth,
          imageHeight: item.imageHeight,
        );
        final compressed = await FlutterImageCompress.compressWithList(bytes, quality: 88);

        await _client.storage.from(_bucketPostMedia).uploadBinary(
              storagePath,
              compressed,
              fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'),
            );

        uploadedPaths.add(storagePath);
        final publicUrl = _publicUrl(storagePath);

        mediaRows.add({
          'post_id': postId,
          'url': publicUrl,
          'type': 'image',
          'sort_order': item.sortOrder,
        });

        final step = 12 + (((i + 1) / total) * uploadSpan).round();
        report(step);
      }

      await _client.from('post_media').insert(mediaRows);
    } catch (error) {
      await _rollbackCreate(postId: postId, storagePaths: uploadedPaths);
      rethrow;
    }

    report(100);
    return postId;
  }

  String _publicUrl(String path) {
    final base = _client.storage.from(_bucketPostMedia).getPublicUrl(path);
    return '$base?v=${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<void> _rollbackCreate({
    required String postId,
    required List<String> storagePaths,
  }) async {
    if (storagePaths.isNotEmpty) {
      try {
        await _client.storage.from(_bucketPostMedia).remove(storagePaths);
      } catch (_) {
        // best effort
      }
    }

    try {
      await _client.from('posts').delete().eq('id', postId);
    } catch (_) {
      // best effort
    }
  }

  String _newMediaId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20, 32)}';
  }
}
