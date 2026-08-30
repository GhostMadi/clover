import 'dart:math';

import 'package:clover/core/shared/image_select/app_image_edit_exporter.dart';
import 'package:clover/feature/_post_/marker_create/data/model/marker_create_request.dart';
import 'package:clover/feature/_catalog_/marker_tags/data/repository/marker_tags_repository.dart';
import 'package:clover/feature/_settings_/settings_filter/data/repository/filter_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class MarkerCreateRepository {
  Future<MarkerCreateResponse> createMarker({
    required MarkerCreateRequest request,
    ValueChanged<int>? onProgress,
  });
}

@LazySingleton(as: MarkerCreateRepository)
class MarkerCreateRepositoryImpl implements MarkerCreateRepository {
  MarkerCreateRepositoryImpl(this._client, this._markerTagsRepository, this._filterRepository);

  final SupabaseClient _client;
  final MarkerTagsRepository _markerTagsRepository;
  final FilterRepository _filterRepository;

  static const _bucketPostMedia = 'post_media';

  @override
  Future<MarkerCreateResponse> createMarker({
    required MarkerCreateRequest request,
    ValueChanged<int>? onProgress,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      throw StateError('Нет сессии: войдите в аккаунт');
    }
    if (request.media.isEmpty) {
      throw ArgumentError('Нужно хотя бы одно фото');
    }

    final lat = request.location.latitude;
    final lng = request.location.longitude;
    if (lat == null || lng == null) {
      throw ArgumentError('У местоположения нет координат');
    }

    final duration = request.duration;
    if (duration.inMinutes <= 0 || duration > const Duration(hours: 24)) {
      throw ArgumentError('Длительность события должна быть от 1 мин до 24 ч');
    }

    void report(int value) => onProgress?.call(value.clamp(0, 100));

    report(5);

    final markerRow = await _client
        .from('markers')
        .insert(_markerInsertRow(uid: uid, request: request, lat: lat, lng: lng))
        .select('id')
        .single();

    final markerId = (markerRow['id'] as String?)?.trim();
    if (markerId == null || markerId.isEmpty) {
      throw StateError('Не удалось создать маркер');
    }

    report(12);

    String? postId;
    final uploadedPaths = <String>[];

    try {
      final postRow = await _client
          .from('posts')
          .insert(_postInsertRow(uid: uid, request: request, markerId: markerId))
          .select('id')
          .single();

      postId = (postRow['id'] as String?)?.trim();
      if (postId == null || postId.isEmpty) {
        throw StateError('Не удалось создать пост');
      }

      report(18);

      final mediaRows = <Map<String, dynamic>>[];
      String? coverUrl;
      final total = request.media.length;
      const uploadSpan = 62;

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
        coverUrl ??= publicUrl;

        mediaRows.add({
          'post_id': postId,
          'url': publicUrl,
          'type': 'image',
          'sort_order': item.sortOrder,
        });

        final step = 18 + (((i + 1) / total) * uploadSpan).round();
        report(step);
      }

      await _client.from('post_media').insert(mediaRows);

      report(84);

      if (coverUrl != null) {
        await _client.from('markers').update({'cover_image_url': coverUrl}).eq('id', markerId);
      }

      report(90);

      if (request.tagIds.isNotEmpty) {
        await _markerTagsRepository.setForMarker(markerId: markerId, tagKeys: request.tagIds);
        await _markerTagsRepository.setForPost(postId: postId, tagKeys: request.tagIds);
      }

      if (request.filterValues.isNotEmpty) {
        await _filterRepository.setPostFilters(postId: postId, selectionKeys: request.filterValues);
      }

      report(100);

      return MarkerCreateResponse(markerId: markerId, postId: postId);
    } catch (error) {
      await _rollbackCreate(
        markerId: markerId,
        postId: postId,
        storagePaths: uploadedPaths,
      );
      rethrow;
    }
  }

  Map<String, dynamic> _markerInsertRow({
    required String uid,
    required MarkerCreateRequest request,
    required double lat,
    required double lng,
  }) {
    final location = request.location;
    final primary = location.addressPrimary.trim();
    final cyrillic = location.addressCyrillic?.trim();
    final country = location.countryCode?.trim().toLowerCase();
    final city = location.cityCode?.trim();

    return {
      'owner_id': uid,
      'text_emoji': request.textEmoji,
      'location_id': location.id,
      'location': 'SRID=4326;POINT($lng $lat)',
      'event_time': request.eventTime.toUtc().toIso8601String(),
      'duration': _formatPgInterval(request.duration),
      if (primary.isNotEmpty) 'address_primary': primary,
      if (cyrillic != null && cyrillic.isNotEmpty) 'address_cyrillic': cyrillic,
      if (country != null && country.isNotEmpty && city != null && city.isNotEmpty) ...{
        'country_code': country,
        'city_code': city,
      },
    };
  }

  Map<String, dynamic> _postInsertRow({
    required String uid,
    required MarkerCreateRequest request,
    required String markerId,
  }) {
    final emoji = request.textEmoji.trim();

    return {
      'user_id': uid,
      'marker_id': markerId,
      'title': request.title.isEmpty ? null : request.title,
      'description': request.description.isEmpty ? null : request.description,
      if (emoji.isNotEmpty) 'text_emoji': emoji,
      'location_id': request.location.id,
    };
  }

  String _formatPgInterval(Duration duration) {
    final totalMinutes = duration.inMinutes;
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;

    if (hours == 0) return '$minutes minutes';
    if (minutes == 0) return '$hours hours';
    return '$hours hours $minutes minutes';
  }

  String _publicUrl(String path) {
    final base = _client.storage.from(_bucketPostMedia).getPublicUrl(path);
    return '$base?v=${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<void> _rollbackCreate({
    required String markerId,
    String? postId,
    required List<String> storagePaths,
  }) async {
    if (storagePaths.isNotEmpty) {
      try {
        await _client.storage.from(_bucketPostMedia).remove(storagePaths);
      } catch (_) {}
    }

    if (postId != null && postId.isNotEmpty) {
      try {
        await _client.from('posts').delete().eq('id', postId);
      } catch (_) {}
    }

    try {
      await _client.from('markers').delete().eq('id', markerId);
    } catch (_) {}
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
